// File: html/script.js
let candidates = [];
let settings = {};
let selectedCandidate = null;

// Show and hide containers
function showContainer(id) {
    document.querySelectorAll('.container').forEach(container => {
        container.style.display = 'none';
    });
    document.getElementById(id).style.display = 'block';
}

// Initialize event listeners
document.addEventListener('DOMContentLoaded', function() {
    // Close buttons
    document.querySelectorAll('.close-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            closeAllMenus();
            fetch('https://elections/closeMenu', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        });
    });

    // Main menu options
    document.getElementById('register-option').addEventListener('click', function() {
        showContainer('registration-form');
    });
    
    document.getElementById('vote-option').addEventListener('click', function() {
        showContainer('voting-screen');
        populateCandidates();
    });
    
    document.getElementById('view-candidates-option').addEventListener('click', function() {
        showContainer('voting-screen');
        populateCandidates(true); // view only
    });

    // Form submission
    document.getElementById('candidate-form').addEventListener('submit', function(e) {
        e.preventDefault();
        
        const formData = {
            slogan: document.getElementById('slogan').value,
            promises: document.getElementById('promises').value,
            party: document.getElementById('party').value,
            photo: document.getElementById('photo').value || 'default.jpg'
        };
        
        fetch('https://elections/registerCandidate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(formData)
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                document.getElementById('candidate-form').reset();
                showContainer('main-menu');
            }
        });
    });

    // Vote button
    document.getElementById('vote-button').addEventListener('click', function() {
        if (selectedCandidate) {
            fetch('https://elections/voteForCandidate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ citizenid: selectedCandidate.citizenid })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showContainer('main-menu');
                }
            });
        }
    });
    
    // Admin panel controls
    document.getElementById('toggle-registration').addEventListener('change', function() {
        fetch('https://elections/toggleRegistration', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ state: this.checked })
        });
    });
    
    document.getElementById('toggle-voting').addEventListener('change', function() {
        fetch('https://elections/toggleVoting', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ state: this.checked })
        });
    });
    
    document.getElementById('reset-election').addEventListener('click', function() {
            fetch('https://elections/resetElection', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
    });
    
    document.getElementById('announce-results').addEventListener('click', function() {
        fetch('https://elections/announceResults', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    });
});

// Close all menus
function closeAllMenus() {
    document.querySelectorAll('.container').forEach(container => {
        container.style.display = 'none';
    });
}

// Populate candidates list
function populateCandidates(viewOnly = false) {
    const container = document.getElementById('voting-candidates-list');
    container.innerHTML = '';
    
    if (candidates.length === 0) {
        container.innerHTML = '<div class="no-candidates">No candidates have registered yet.</div>';
        return;
    }
    
    candidates.forEach(candidate => {
        const candidateCard = document.createElement('div');
        candidateCard.className = 'candidate-card';
        candidateCard.innerHTML = `
            <img src="${candidate.photo}" alt="${candidate.name}">
            <div class="candidate-card-body">
                <h3>${candidate.name}</h3>
                <p class="party">${candidate.party}</p>
                <p class="slogan">"${candidate.slogan}"</p>
            </div>
        `;
        
        candidateCard.addEventListener('click', function() {
            selectedCandidate = candidate;
            displayCandidateDetails(candidate, viewOnly);
        });
        
        container.appendChild(candidateCard);
    });
}

// Display candidate details
function displayCandidateDetails(candidate, viewOnly = false) {
    document.getElementById('candidate-photo').src = candidate.photo;
    document.getElementById('candidate-name').textContent = candidate.name;
    document.getElementById('candidate-party').textContent = candidate.party;
    document.getElementById('candidate-slogan').textContent = candidate.slogan;
    document.getElementById('candidate-promises').textContent = candidate.promises;
    
    // Show/hide vote button based on viewOnly parameter and if voting is open
    const voteButton = document.getElementById('vote-button');
    if (viewOnly || !settings.voting_open) {
        voteButton.style.display = 'none';
    } else {
        voteButton.style.display = 'block';
    }
    
    showContainer('candidate-details');
}

// Show election results
function displayResults(candidatesList, winner) {
    document.getElementById('winner-photo').src = winner.photo;
    document.getElementById('winner-name').textContent = winner.name;
    document.getElementById('winner-party').textContent = winner.party;
    document.getElementById('winner-votes').textContent = `${winner.votes} votes`;
    
    const resultsList = document.getElementById('results-list');
    resultsList.innerHTML = '';
    
    candidatesList.forEach((candidate, index) => {
        const resultItem = document.createElement('div');
        resultItem.className = 'result-item';
        resultItem.innerHTML = `
            <div class="position">${index + 1}</div>
            <img src="${candidate.photo}" alt="${candidate.name}" class="result-photo">
            <div class="result-info">
                <h4>${candidate.name}</h4>
                <p>${candidate.party}</p>
            </div>
            <div class="result-votes">${candidate.votes} votes</div>
        `;
        
        resultsList.appendChild(resultItem);
    });
    
    showContainer('results-screen');
}

// Update admin panel
function updateAdminPanel() {
    document.getElementById('toggle-registration').checked = settings.registration_open;
    document.getElementById('toggle-voting').checked = settings.voting_open;
    
    const candidatesList = document.getElementById('admin-candidates-list');
    candidatesList.innerHTML = '';
    
    if (candidates.length === 0) {
        candidatesList.innerHTML = '<div class="no-candidates">No candidates have registered yet.</div>';
        return;
    }
    
    candidates.forEach(candidate => {
        const candidateItem = document.createElement('div');
        candidateItem.className = 'admin-candidate-item';
        candidateItem.innerHTML = `
            <img src="${candidate.photo}" alt="${candidate.name}">
            <div class="admin-candidate-info">
                <h4>${candidate.name}</h4>
                <p>${candidate.party}</p>
            </div>
            <div class="admin-candidate-votes">${candidate.votes} votes</div>
        `;
        
        candidatesList.appendChild(candidateItem);
    });
}

// Listen for NUI messages from client
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch (data.action) {
        case 'showMainMenu':
            candidates = data.candidates;
            settings = data.settings;
            
            // Enable/disable buttons based on settings and player state
            document.getElementById('register-option').style.opacity = data.canRegister ? '1' : '0.5';
            document.getElementById('register-option').style.pointerEvents = data.canRegister ? 'auto' : 'none';
            
            document.getElementById('vote-option').style.opacity = data.canVote ? '1' : '0.5';
            document.getElementById('vote-option').style.pointerEvents = data.canVote ? 'auto' : 'none';
            
            showContainer('main-menu');
            break;
            
        case 'showResults':
            candidates = data.candidates;
            settings = data.settings;
            displayResults(candidates, data.winner);
            break;
            
        case 'showAdminPanel':
            candidates = data.candidates;
            settings = data.settings;
            updateAdminPanel();
            showContainer('admin-panel');
            break;
    }
});

// Escape key to close menus
document.addEventListener('keyup', function(e) {
    if (e.key === 'Escape') {
        closeAllMenus();
        fetch('https://elections/closeMenu', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
});