import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { CommonModule } from '@angular/common';
import { environment } from '../environments/environment';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="container">
      <h1>{{ title }}</h1>
      <div class="message-box">
        <h2>Message du Backend:</h2>
        <p *ngIf="backendMessage">{{ backendMessage }}</p>
        <p *ngIf="error" class="error">{{ error }}</p>
        <button (click)="fetchMessage()">Rafraîchir</button>
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
      max-width: 600px;
      margin: 2rem;
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
      margin-top: 1rem;
    }

    h2 {
      color: #333;
      font-size: 1.5rem;
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

    button:hover {
      background: #764ba2;
      transform: translateY(-2px);
      box-shadow: 0 5px 15px rgba(0,0,0,0.2);
    }
  `]
})
export class AppComponent implements OnInit {
  title = 'Hello World Frontend!';
  backendMessage = '';
  error = '';

  constructor(private readonly http: HttpClient) {}

  ngOnInit() {
    this.fetchMessage();
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
}
