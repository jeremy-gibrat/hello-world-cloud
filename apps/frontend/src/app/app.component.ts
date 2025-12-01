import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { environment } from '../environments/environment';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="container">
      <h1>{{ title }}</h1>
      
      <div class="message-box">
        <h2>Message du Backend:</h2>
        <p *ngIf="backendMessage">{{ backendMessage }}</p>
        <p *ngIf="error" class="error">{{ error }}</p>
        <button (click)="fetchMessage()">Rafraîchir</button>
      </div>

      <div class="rabbitmq-section">
        <h2>🐰 RabbitMQ Messages</h2>
        
        <div class="send-message">
          <input 
            type="text" 
            [(ngModel)]="newMessage" 
            placeholder="Entrez un message..."
            (keyup.enter)="sendMessage()"
          />
          <button (click)="sendMessage()" [disabled]="!newMessage.trim()">
            Envoyer
          </button>
        </div>

        <div class="received-messages">
          <h3>Messages reçus ({{ receivedMessages.length }}):</h3>
          <div class="messages-list" *ngIf="receivedMessages.length > 0">
            <div class="message-item" *ngFor="let msg of receivedMessages; let i = index">
              <span class="message-number">#{{ receivedMessages.length - i }}</span>
              <span class="message-text">{{ msg }}</span>
            </div>
          </div>
          <p *ngIf="receivedMessages.length === 0" class="no-messages">
            Aucun message reçu pour le moment
          </p>
          <button (click)="fetchReceivedMessages()" class="refresh-btn">
            🔄 Rafraîchir les messages
          </button>
        </div>
      </div>

      <div class="elasticsearch-section">
        <h2>🔍 Elasticsearch Data</h2>
        
        <div class="index-selector">
          <label for="index-select">Index:</label>
          <select 
            id="index-select" 
            [(ngModel)]="selectedIndex" 
            (change)="onIndexChange()"
          >
            <option *ngFor="let index of elasticsearchIndices" [value]="index">
              {{ index }}
            </option>
          </select>
          <button (click)="searchElasticsearch()" class="refresh-btn">
            🔄 Rafraîchir
          </button>
        </div>

        <div class="es-stats">
          <p>Total: {{ elasticsearchTotal }} documents</p>
        </div>

        <div class="es-results" *ngIf="elasticsearchDocs.length > 0">
          <div class="es-doc" *ngFor="let doc of elasticsearchDocs">
            <div class="doc-id">ID: {{ doc.id }}</div>
            <pre class="doc-content">{{ doc.source | json }}</pre>
          </div>
        </div>
        <p *ngIf="elasticsearchDocs.length === 0" class="no-messages">
          Aucun document trouvé dans cet index
        </p>
      </div>

      <div class="postgres-section">
        <h2>🐘 PostgreSQL Users</h2>
        
        <div class="user-form">
          <input 
            type="text" 
            [(ngModel)]="newUserName" 
            placeholder="Nom complet..."
            class="user-input"
          />
          <input 
            type="email" 
            [(ngModel)]="newUserEmail" 
            placeholder="Email..."
            class="user-input"
            (keyup.enter)="createUser()"
          />
          <button (click)="createUser()" [disabled]="!newUserName.trim() || !newUserEmail.trim()">
            ➕ Ajouter
          </button>
        </div>

        <div class="users-list">
          <h3>Utilisateurs ({{ users.length }}):</h3>
          <div class="user-items" *ngIf="users.length > 0">
            <div class="user-item" *ngFor="let user of users">
              <div class="user-info">
                <span class="user-name">{{ user.name }}</span>
                <span class="user-email">{{ user.email }}</span>
                <span class="user-date">{{ user.createdAt | date:'short' }}</span>
              </div>
              <button (click)="deleteUser(user.id)" class="delete-btn">🗑️</button>
            </div>
          </div>
          <p *ngIf="users.length === 0" class="no-messages">
            Aucun utilisateur dans la base de données
          </p>
          <button (click)="fetchUsers()" class="refresh-btn">
            🔄 Rafraîchir
          </button>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .container {
      text-align: center;
      background: white;
      padding: 3rem;
      border-radius: 20px;
      box-shadow: 0 20px 60px rgba(0,0,0,0.3);
      max-width: 800px;
      margin: 2rem auto;
    }

    h1 {
      color: #667eea;
      margin-bottom: 2rem;
      font-size: 2.5rem;
    }

    .message-box {
      background: #f7f7f7;
      padding: 2rem;
      border-radius: 10px;
      margin-bottom: 2rem;
    }

    h2 {
      color: #333;
      font-size: 1.5rem;
      margin-bottom: 1rem;
    }

    h3 {
      color: #555;
      font-size: 1.2rem;
      margin-bottom: 1rem;
    }

    p {
      font-size: 1.2rem;
      color: #555;
      margin: 1rem 0;
    }

    .error {
      color: #e74c3c;
    }

    button {
      background: #667eea;
      color: white;
      border: none;
      padding: 12px 30px;
      border-radius: 25px;
      font-size: 1rem;
      cursor: pointer;
      margin-top: 1rem;
      transition: all 0.3s;
    }

    button:hover:not(:disabled) {
      background: #764ba2;
      transform: translateY(-2px);
      box-shadow: 0 5px 15px rgba(0,0,0,0.2);
    }

    button:disabled {
      background: #ccc;
      cursor: not-allowed;
    }

    .rabbitmq-section {
      background: #f0f4ff;
      padding: 2rem;
      border-radius: 10px;
      margin-top: 2rem;
    }

    .send-message {
      display: flex;
      gap: 1rem;
      margin-bottom: 2rem;
      justify-content: center;
    }

    .send-message input {
      flex: 1;
      max-width: 400px;
      padding: 12px 20px;
      border: 2px solid #667eea;
      border-radius: 25px;
      font-size: 1rem;
      outline: none;
      transition: all 0.3s;
    }

    .send-message input:focus {
      border-color: #764ba2;
      box-shadow: 0 0 10px rgba(102, 126, 234, 0.3);
    }

    .received-messages {
      margin-top: 2rem;
    }

    .messages-list {
      max-height: 400px;
      overflow-y: auto;
      background: white;
      border-radius: 10px;
      padding: 1rem;
      margin: 1rem 0;
    }

    .message-item {
      display: flex;
      align-items: center;
      gap: 1rem;
      padding: 12px;
      margin: 8px 0;
      background: #f7f7f7;
      border-radius: 8px;
      text-align: left;
      transition: all 0.2s;
    }

    .message-item:hover {
      background: #e8ecff;
      transform: translateX(5px);
    }

    .message-number {
      font-weight: bold;
      color: #667eea;
      min-width: 40px;
    }

    .message-text {
      color: #333;
      flex: 1;
    }

    .no-messages {
      color: #999;
      font-style: italic;
      margin: 2rem 0;
    }

    .refresh-btn {
      background: #48bb78;
      margin-top: 1rem;
    }

    .refresh-btn:hover {
      background: #38a169;
    }

    .elasticsearch-section {
      background: #fff5e6;
      padding: 2rem;
      border-radius: 10px;
      margin-top: 2rem;
    }

    .index-selector {
      display: flex;
      gap: 1rem;
      align-items: center;
      justify-content: center;
      margin-bottom: 1rem;
    }

    .index-selector label {
      font-weight: bold;
      color: #333;
    }

    .index-selector select {
      padding: 8px 16px;
      border: 2px solid #ff9800;
      border-radius: 8px;
      font-size: 1rem;
      outline: none;
      background: white;
      cursor: pointer;
    }

    .index-selector select:focus {
      border-color: #f57c00;
    }

    .es-stats {
      color: #666;
      margin: 1rem 0;
      font-size: 1.1rem;
    }

    .es-results {
      max-height: 500px;
      overflow-y: auto;
      background: white;
      border-radius: 10px;
      padding: 1rem;
      margin-top: 1rem;
    }

    .es-doc {
      background: #f7f7f7;
      border: 1px solid #ddd;
      border-radius: 8px;
      padding: 1rem;
      margin-bottom: 1rem;
    }

    .doc-id {
      font-weight: bold;
      color: #ff9800;
      margin-bottom: 0.5rem;
    }

    .doc-content {
      background: #2d2d2d;
      color: #f8f8f2;
      padding: 1rem;
      border-radius: 6px;
      overflow-x: auto;
      font-size: 0.9rem;
      text-align: left;
      white-space: pre-wrap;
      word-wrap: break-word;
    }

    .postgres-section {
      background: #e6f7ff;
      padding: 2rem;
      border-radius: 10px;
      margin-top: 2rem;
    }

    .user-form {
      display: flex;
      gap: 1rem;
      margin-bottom: 2rem;
      justify-content: center;
      flex-wrap: wrap;
    }

    .user-input {
      padding: 12px 20px;
      border: 2px solid #1890ff;
      border-radius: 25px;
      font-size: 1rem;
      outline: none;
      min-width: 200px;
      transition: all 0.3s;
    }

    .user-input:focus {
      border-color: #096dd9;
      box-shadow: 0 0 10px rgba(24, 144, 255, 0.3);
    }

    .users-list {
      margin-top: 2rem;
    }

    .user-items {
      max-height: 400px;
      overflow-y: auto;
      background: white;
      border-radius: 10px;
      padding: 1rem;
      margin: 1rem 0;
    }

    .user-item {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 12px;
      margin: 8px 0;
      background: #f7f7f7;
      border-radius: 8px;
      transition: all 0.2s;
    }

    .user-item:hover {
      background: #e6f7ff;
      transform: translateX(5px);
    }

    .user-info {
      display: flex;
      flex-direction: column;
      align-items: flex-start;
      gap: 4px;
      flex: 1;
    }

    .user-name {
      font-weight: bold;
      color: #1890ff;
      font-size: 1.1rem;
    }

    .user-email {
      color: #666;
      font-size: 0.95rem;
    }

    .user-date {
      color: #999;
      font-size: 0.85rem;
    }

    .delete-btn {
      background: #ff4d4f;
      padding: 8px 16px;
      font-size: 1.2rem;
      margin: 0;
    }

    .delete-btn:hover {
      background: #cf1322;
    }
  `]
})
export class AppComponent implements OnInit {
  title = 'Hello World Frontend!';
  backendMessage = '';
  error = '';
  newMessage = '';
  receivedMessages: string[] = [];
  
  // Elasticsearch
  elasticsearchIndices: string[] = [];
  selectedIndex = 'logs-2024.12.01';
  elasticsearchDocs: any[] = [];
  elasticsearchTotal = 0;

  // PostgreSQL Users
  users: any[] = [];
  newUserName = '';
  newUserEmail = '';
  editingUser: any = null;

  constructor(private readonly http: HttpClient) {}

  ngOnInit() {
    this.fetchMessage();
    this.fetchReceivedMessages();
    this.fetchElasticsearchIndices();
    this.searchElasticsearch();
    this.fetchUsers();
    this.initializeUsers();
    
    // Auto-refresh des messages toutes les 5 secondes
    setInterval(() => {
      this.fetchReceivedMessages();
      this.searchElasticsearch();
    }, 5000);
  }

  fetchMessage() {
    this.error = '';
    this.backendMessage = '';
    
    const backendUrl = environment.backendUrl;
    
    this.http.get<{message: string}>(`${backendUrl}/api/hello`)
      .subscribe({
        next: (response: {message: string}) => {
          this.backendMessage = response.message;
        },
        error: (err: any) => {
          this.error = `Erreur de connexion au backend: ${err.message}`;
          console.error('Error:', err);
        }
      });
  }

  sendMessage() {
    if (!this.newMessage.trim()) {
      return;
    }

    const backendUrl = environment.backendUrl;
    
    this.http.post<{status: string, message: string}>(
      `${backendUrl}/api/messages/send`,
      { message: this.newMessage }
    ).subscribe({
      next: (response) => {
        console.log('Message sent:', response);
        this.newMessage = '';
        // Rafraîchir les messages après envoi
        setTimeout(() => this.fetchReceivedMessages(), 500);
      },
      error: (err) => {
        console.error('Error sending message:', err);
        alert('Erreur lors de l\'envoi du message');
      }
    });
  }

  fetchReceivedMessages() {
    const backendUrl = environment.backendUrl;
    
    this.http.get<string[]>(`${backendUrl}/api/messages/received`)
      .subscribe({
        next: (messages) => {
          this.receivedMessages = messages;
        },
        error: (err) => {
          console.error('Error fetching messages:', err);
        }
      });
  }

  fetchElasticsearchIndices() {
    const backendUrl = environment.backendUrl;
    
    this.http.get<{indices: string[]}>(`${backendUrl}/api/elasticsearch/indices`)
      .subscribe({
        next: (response) => {
          this.elasticsearchIndices = response.indices.filter(idx => !idx.startsWith('.'));
          if (this.elasticsearchIndices.length > 0 && !this.selectedIndex) {
            this.selectedIndex = this.elasticsearchIndices[0];
          }
        },
        error: (err) => {
          console.error('Error fetching ES indices:', err);
        }
      });
  }

  searchElasticsearch() {
    if (!this.selectedIndex) return;
    
    const backendUrl = environment.backendUrl;
    
    this.http.get<{total: number, documents: any[]}>(`${backendUrl}/api/elasticsearch/search/${this.selectedIndex}?size=10`)
      .subscribe({
        next: (response) => {
          this.elasticsearchTotal = response.total;
          this.elasticsearchDocs = response.documents;
        },
        error: (err) => {
          console.error('Error searching ES:', err);
          this.elasticsearchDocs = [];
          this.elasticsearchTotal = 0;
        }
      });
  }

  onIndexChange() {
    this.searchElasticsearch();
  }

  // PostgreSQL Users methods
  fetchUsers() {
    const backendUrl = environment.backendUrl;
    
    this.http.get<any[]>(`${backendUrl}/api/users`)
      .subscribe({
        next: (users) => {
          this.users = users;
        },
        error: (err) => {
          console.error('Error fetching users:', err);
        }
      });
  }

  initializeUsers() {
    const backendUrl = environment.backendUrl;
    
    this.http.post(`${backendUrl}/api/users/init`, {})
      .subscribe({
        next: (response) => {
          console.log('Users initialized:', response);
          this.fetchUsers();
        },
        error: (err) => {
          console.error('Error initializing users:', err);
        }
      });
  }

  createUser() {
    if (!this.newUserName.trim() || !this.newUserEmail.trim()) {
      alert('Veuillez remplir tous les champs');
      return;
    }

    const backendUrl = environment.backendUrl;
    
    this.http.post(`${backendUrl}/api/users`, {
      name: this.newUserName,
      email: this.newUserEmail
    }).subscribe({
      next: () => {
        this.newUserName = '';
        this.newUserEmail = '';
        this.fetchUsers();
      },
      error: (err) => {
        alert('Erreur: ' + (err.error?.error || 'Impossible de créer l\'utilisateur'));
      }
    });
  }

  deleteUser(id: number) {
    if (!confirm('Êtes-vous sûr de vouloir supprimer cet utilisateur ?')) {
      return;
    }

    const backendUrl = environment.backendUrl;
    
    this.http.delete(`${backendUrl}/api/users/${id}`)
      .subscribe({
        next: () => {
          this.fetchUsers();
        },
        error: (err) => {
          alert('Erreur lors de la suppression');
        }
      });
  }
}
