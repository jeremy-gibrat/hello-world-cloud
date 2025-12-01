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
  `]
})
export class AppComponent implements OnInit {
  title = 'Hello World Frontend!';
  backendMessage = '';
  error = '';
  newMessage = '';
  receivedMessages: string[] = [];

  constructor(private readonly http: HttpClient) {}

  ngOnInit() {
    this.fetchMessage();
    this.fetchReceivedMessages();
    
    // Auto-refresh des messages toutes les 5 secondes
    setInterval(() => {
      this.fetchReceivedMessages();
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
}
