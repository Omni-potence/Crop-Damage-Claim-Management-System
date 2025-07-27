import React, { useState, useEffect } from 'react';
import { useFirebase } from '../contexts/FirebaseContext';
import { collection, query, onSnapshot, orderBy, where, updateDoc, doc, getDoc } from 'firebase/firestore';
import { ref, getDownloadURL } from 'firebase/storage';
import { format } from 'date-fns';

function DashboardPage() {
  const { db, storage } = useFirebase();
  const [claims, setClaims] = useState([]);
  const [selectedClaim, setSelectedClaim] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [rejectReason, setRejectReason] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [filterDamageType, setFilterDamageType] = useState('all');
  // const [filterDateRange, setFilterDateRange] = useState(''); // e.g., 'last7days', 'last30days'

  useEffect(() => {
    let claimsQuery = collection(db, 'claims');

    if (filterStatus !== 'all') {
      claimsQuery = query(claimsQuery, where('status', '==', filterStatus));
    }
    if (filterDamageType !== 'all') {
      claimsQuery = query(claimsQuery, where('reason', '==', filterDamageType));
    }
    // Date range filtering would require more complex logic, e.g., using start/end dates

    claimsQuery = query(claimsQuery, orderBy('submitted_at', 'desc'));

    const unsubscribe = onSnapshot(claimsQuery, async (snapshot) => {
      const claimsData = await Promise.all(snapshot.docs.map(async (claimDoc) => {
        const data = claimDoc.data();
        let imageUrl = '';
        if (data.image_url) {
          try {
            imageUrl = await getDownloadURL(ref(storage, data.image_url));
          } catch (error) {
            console.error('Error fetching image URL:', error);
          }
        }

        let farmerName = 'N/A';
        if (data.user_id) {
          try {
            const userDocRef = doc(db, 'users', data.user_id);
            const userDocSnap = await getDoc(userDocRef);
            if (userDocSnap.exists()) {
              farmerName = userDocSnap.data().name || 'N/A';
            }
          } catch (error) {
            console.error('Error fetching farmer name:', error);
          }
        }

        return { id: claimDoc.id, ...data, imageUrl, farmerName };
      }));
      setClaims(claimsData);
    });

    return unsubscribe;
  }, [db, storage, filterStatus, filterDamageType]);

  const handleViewClaim = (claim) => {
    setSelectedClaim(claim);
    setIsModalOpen(true);
  };

  const handleApprove = async () => {
    if (selectedClaim) {
      const claimRef = doc(db, 'claims', selectedClaim.id);
      await updateDoc(claimRef, { status: 'approved', officer_remarks: '' });
      setIsModalOpen(false);
    }
  };

  const handleReject = async () => {
    if (selectedClaim && rejectReason.trim() !== '') {
      const claimRef = doc(db, 'claims', selectedClaim.id);
      await updateDoc(claimRef, { status: 'rejected', officer_remarks: rejectReason });
      setIsModalOpen(false);
      setRejectReason('');
    } else {
      alert('Please provide a reason for rejection.');
    }
  };

  const getMapUrl = (gps) => {
    if (gps && gps.latitude && gps.longitude) {
      // Replace YOUR_GOOGLE_MAPS_API_KEY with an actual key if you want to embed maps
      return `https://www.google.com/maps/embed/v1/view?key=YOUR_GOOGLE_MAPS_API_KEY&center=${gps.latitude},${gps.longitude}&zoom=15`;
    }
    return '';
  };

  return (
    <div style={{ display: 'flex', minHeight: '100vh', backgroundColor: '#f8f8f8' }}>
      {/* Sidebar */}
      <aside style={{ width: '250px', backgroundColor: '#fff', boxShadow: '2px 0 5px rgba(0,0,0,0.1)', padding: '20px' }}>
        <h2 style={{ fontSize: '1.8em', fontWeight: 'bold', marginBottom: '20px' }}>Officer Portal</h2>
        <nav>
          <ul style={{ listStyle: 'none', padding: 0 }}>
            <li style={{ marginBottom: '10px' }}>
              <button style={{ width: '100%', padding: '10px', textAlign: 'left', border: 'none', background: 'none', cursor: 'pointer', fontSize: '1.1em' }}>Home</button>
            </li>
            <li style={{ marginBottom: '10px' }}>
              <button style={{ width: '100%', padding: '10px', textAlign: 'left', border: 'none', background: 'none', cursor: 'pointer', fontSize: '1.1em' }}>Claims</button>
            </li>
          </ul>
        </nav>
      </aside>

      {/* Main Content */}
      <main style={{ flex: 1, padding: '30px', overflowY: 'auto' }}>
        <h1 style={{ fontSize: '2.5em', fontWeight: 'bold', marginBottom: '25px' }}>Claim Review Dashboard</h1>

        {/* Filters */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '20px', marginBottom: '25px' }}>
          <div>
            <label htmlFor="status-filter" style={{ display: 'block', marginBottom: '5px' }}>Filter by Status</label>
            <select id="status-filter" value={filterStatus} onChange={(e) => setFilterStatus(e.target.value)} style={{ width: '100%', padding: '8px', border: '1px solid #ddd', borderRadius: '4px' }}>
              <option value="all">All Statuses</option>
              <option value="pending">Pending</option>
              <option value="approved">Approved</option>
              <option value="rejected">Rejected</option>
            </select>
          </div>
          <div>
            <label htmlFor="damage-type-filter" style={{ display: 'block', marginBottom: '5px' }}>Filter by Damage Type</label>
            <select id="damage-type-filter" value={filterDamageType} onChange={(e) => setFilterDamageType(e.target.value)} style={{ width: '100%', padding: '8px', border: '1px solid #ddd', borderRadius: '4px' }}>
              <option value="all">All Damage Types</option>
              <option value="Flood">Flood</option>
              <option value="Drought">Drought</option>
              <option value="Pest">Pest Infestation</option>
              <option value="Hail">Hailstorm</option>
              <option value="Other">Other</option>
            </select>
          </div>
          {/* Date Range Filter - Placeholder for future implementation */}
          <div>
            <label htmlFor="date-range-filter" style={{ display: 'block', marginBottom: '5px' }}>Filter by Date Range</label>
            <input id="date-range-filter" type="text" placeholder="e.g., Last 7 Days" disabled style={{ width: '100%', padding: '8px', border: '1px solid #ddd', borderRadius: '4px', backgroundColor: '#eee' }} />
          </div>
        </div>

        {/* Claims Table */}
        <div style={{ backgroundColor: '#fff', borderRadius: '8px', boxShadow: '0 2px 4px rgba(0,0,0,0.1)', overflowX: 'auto' }}>
          <h3 style={{ fontSize: '1.5em', fontWeight: 'bold', padding: '20px', borderBottom: '1px solid #eee' }}>Submitted Claims</h3>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr>
                <th style={{ padding: '12px 20px', textAlign: 'left', borderBottom: '1px solid #eee' }}>Farmer Name</th>
                <th style={{ padding: '12px 20px', textAlign: 'left', borderBottom: '1px solid #eee' }}>Submission Date</th>
                <th style={{ padding: '12px 20px', textAlign: 'left', borderBottom: '1px solid #eee' }}>Damage Type</th>
                <th style={{ padding: '12px 20px', textAlign: 'left', borderBottom: '1px solid #eee' }}>Status</th>
                <th style={{ padding: '12px 20px', textAlign: 'left', borderBottom: '1px solid #eee' }}>Action</th>
              </tr>
            </thead>
            <tbody>
              {claims.length === 0 ? (
                <tr>
                  <td colSpan="5" style={{ padding: '20px', textAlign: 'center', color: '#666' }}>No claims found.</td>
                </tr>
              ) : (
                claims.map((claim) => (
                  <tr key={claim.id} style={{ borderBottom: '1px solid #eee' }}>
                    <td style={{ padding: '12px 20px' }}>{claim.farmerName || 'N/A'}</td><td style={{ padding: '12px 20px' }}>{claim.submitted_at ? format(claim.submitted_at.toDate(), 'PPP') : 'N/A'}</td><td style={{ padding: '12px 20px' }}>{claim.reason}</td><td style={{ padding: '12px 20px' }}>{claim.status}</td><td style={{ padding: '12px 20px' }}>
                      <button onClick={() => handleViewClaim(claim)} style={{ padding: '8px 12px', backgroundColor: '#007bff', color: '#fff', border: 'none', borderRadius: '4px', cursor: 'pointer' }}>View Details</button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Claim Details Modal */}
        {isModalOpen && selectedClaim && (
          <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000 }}>
            <div style={{ backgroundColor: '#fff', padding: '30px', borderRadius: '8px', maxWidth: '800px', width: '90%', maxHeight: '90vh', overflowY: 'auto', boxShadow: '0 5px 15px rgba(0,0,0,0.3)' }}>
              <h3 style={{ fontSize: '1.8em', fontWeight: 'bold', marginBottom: '15px', borderBottom: '1px solid #eee', paddingBottom: '10px' }}>Claim Details</h3>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 3fr', gap: '15px', marginBottom: '20px' }}>
                <strong style={{ textAlign: 'right' }}>Farmer Name:</strong>
                <div>{selectedClaim.farmerName || 'N/A'}</div>
                <strong style={{ textAlign: 'right' }}>Submission Date:</strong>
                <div>{selectedClaim.submitted_at ? format(selectedClaim.submitted_at.toDate(), 'PPP p') : 'N/A'}</div>
                <strong style={{ textAlign: 'right' }}>Damage Type:</strong>
                <div>{selectedClaim.reason}</div>
                <strong style={{ textAlign: 'right' }}>Status:</strong>
                <div>{selectedClaim.status}</div>
                {selectedClaim.officer_remarks && (
                  <React.Fragment>
                    <strong style={{ textAlign: 'right' }}>Officer Remarks:</strong>
                    <div>{selectedClaim.officer_remarks}</div>
                  </React.Fragment>
                )}
                <strong style={{ textAlign: 'right' }}>Crop Photo:</strong>
                <div>
                  {selectedClaim.imageUrl ? (
                    <img src={selectedClaim.imageUrl} alt="Crop Damage" style={{ maxWidth: '100%', height: 'auto', borderRadius: '4px' }} />
                  ) : (
                    <span>No photo available.</span>
                  )}
                </div>
                <strong style={{ textAlign: 'right' }}>GPS Coordinates:</strong>
                <div>
                  {selectedClaim.gps ? (
                    <React.Fragment>
                      {selectedClaim.gps.latitude}, {selectedClaim.gps.longitude}
                      {getMapUrl(selectedClaim.gps) && (
                        <iframe
                          title="Google Map"
                          width="100%"
                          height="200"
                          frameBorder="0"
                          style={{ border: 0, marginTop: '10px' }}
                          src={getMapUrl(selectedClaim.gps)}
                          allowFullScreen=""
                          aria-hidden="false"
                          tabIndex="0"
                        ></iframe>
                      )}
                    </React.Fragment>
                  ) : (
                    <span>N/A</span>
                  )}
                </div>
                <strong style={{ textAlign: 'right' }}>Supporting Documents:</strong>
                <div>
                  {selectedClaim.document_urls && selectedClaim.document_urls.length > 0 ? (
                    <ul style={{ listStyle: 'disc', paddingLeft: '20px' }}>
                      {selectedClaim.document_urls.map((url, index) => (
                        <li key={index}>
                          <a href={url} target="_blank" rel="noopener noreferrer" style={{ color: '#007bff', textDecoration: 'underline' }}>
                            Document {index + 1}
                          </a>
                        </li>
                      ))}
                    </ul>
                  ) : (
                    <span>No supporting documents.</span>
                  )}
                </div>
              </div>

              {selectedClaim.status.toLowerCase() === 'pending' && (
                <React.Fragment>
                  <div style={{ marginBottom: '15px' }}>
                    <label htmlFor="reject-reason" style={{ display: 'block', marginBottom: '5px' }}>Reason for Rejection:</label>
                    <textarea
                      id="reject-reason"
                      value={rejectReason}
                      onChange={(e) => setRejectReason(e.target.value)}
                      placeholder="Enter reason for rejection (required for rejection)"
                      style={{ width: '100%', padding: '8px', border: '1px solid #ddd', borderRadius: '4px', minHeight: '80px' }}
                    ></textarea>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
                    <button onClick={() => setIsModalOpen(false)} style={{ padding: '10px 15px', border: '1px solid #ccc', borderRadius: '4px', background: 'none', cursor: 'pointer' }}>Cancel</button>
                    <button onClick={handleApprove} style={{ padding: '10px 15px', backgroundColor: '#28a745', color: '#fff', border: 'none', borderRadius: '4px', cursor: 'pointer' }}>Approve</button>
                    <button onClick={handleReject} style={{ padding: '10px 15px', backgroundColor: '#dc3545', color: '#fff', border: 'none', borderRadius: '4px', cursor: 'pointer' }}>Reject</button>
                  </div>
                </React.Fragment>
              )}
              <button onClick={() => setIsModalOpen(false)} style={{ marginTop: '20px', padding: '10px 15px', border: '1px solid #ccc', borderRadius: '4px', background: 'none', cursor: 'pointer' }}>Close</button>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}

export default DashboardPage;
