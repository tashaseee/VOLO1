import React, { useState } from 'react';
import { apiLogin } from '../api';
import { ShieldCheck, Lock, Mail, AlertCircle } from 'lucide-react';

export default function Login({ onLogin }) {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState(null);
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError(null);
        try {
            const data = await apiLogin(email, password);
            if (data.role !== 'admin') {
                setError('Доступ запрещен: Вы не являетесь администратором');
                setLoading(false);
                return;
            }
            onLogin(data.access_token);
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="login-split-page">
            <div className="login-graphic">
                <div className="graphic-overlay"></div>
                <div className="graphic-content">
                    <h1>VOLO Admin</h1>
                    <p>Панель управления платформой</p>
                </div>
                {/* Modern Mountain SVG in VOLO pink */}
                <svg className="mountain-svg" viewBox="0 0 1440 800" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="none">
                    <defs>
                        <linearGradient id="grad1" x1="0%" y1="0%" x2="0%" y2="100%">
                            <stop offset="0%" stopColor="#c55ac3" stopOpacity="0.8" />
                            <stop offset="100%" stopColor="#983296" stopOpacity="1" />
                        </linearGradient>
                        <linearGradient id="grad2" x1="0%" y1="0%" x2="0%" y2="100%">
                            <stop offset="0%" stopColor="#da79d8" stopOpacity="0.6" />
                            <stop offset="100%" stopColor="#7a2879" stopOpacity="1" />
                        </linearGradient>
                    </defs>
                    <path fill="url(#grad2)" d="M0,800 L0,500 L250,300 L500,600 L800,200 L1100,550 L1440,300 L1440,800 Z" />
                    <path fill="url(#grad1)" d="M0,800 L0,600 L300,450 L600,650 L950,350 L1250,550 L1440,400 L1440,800 Z" />
                    <path fill="#ffffff" opacity="0.1" d="M800,200 L950,350 L800,500 Z" />
                    <path fill="#ffffff" opacity="0.1" d="M250,300 L350,420 L250,550 Z" />
                </svg>
            </div>

            <div className="login-form-side">
                <div className="login-card animate-slide-in">
                    <div className="login-header">
                        <div className="logo-badge">
                            <ShieldCheck size={32} />
                        </div>
                        <h2>С возвращением</h2>
                        <p>Введите данные для доступа к панели управления</p>
                    </div>

                    <form onSubmit={handleSubmit} className="login-form">
                        <div className="input-group">
                            <label>Email</label>
                            <div className="input-wrapper">
                                <Mail size={18} className="input-icon" />
                                <input
                                    type="email"
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    required
                                    placeholder="admin@volo.kz"
                                />
                            </div>
                        </div>

                        <div className="input-group">
                            <label>Пароль</label>
                            <div className="input-wrapper">
                                <Lock size={18} className="input-icon" />
                                <input
                                    type="password"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    required
                                    placeholder="••••••••"
                                />
                            </div>
                        </div>

                        {error && (
                            <div className="error-message">
                                <AlertCircle size={16} />
                                <span>{error}</span>
                            </div>
                        )}

                        <button
                            type="submit"
                            className="btn btn-primary login-btn"
                            disabled={loading}
                        >
                            {loading ? 'Вход в систему...' : 'Войти в панель'}
                        </button>
                    </form>
                </div>
            </div>

            <style jsx="true">{`
                .login-split-page {
                    min-height: 100vh;
                    display: flex;
                    width: 100vw;
                    background: var(--bg-main);
                }

                .login-graphic {
                    flex: 1;
                    position: relative;
                    display: none;
                    background: linear-gradient(135deg, #1e1b4b 0%, #311030 100%);
                    overflow: hidden;
                    align-items: center;
                    justify-content: center;
                }

                @media (min-width: 1024px) {
                    .login-graphic {
                        display: flex;
                    }
                }

                .graphic-overlay {
                    position: absolute;
                    inset: 0;
                    background: radial-gradient(circle at center, transparent 0%, rgba(0,0,0,0.4) 100%);
                    z-index: 1;
                }

                .graphic-content {
                    position: absolute;
                    top: 15%;
                    left: 10%;
                    z-index: 2;
                    color: white;
                }

                .graphic-content h1 {
                    font-size: 3.5rem;
                    font-weight: 800;
                    margin-bottom: 0.5rem;
                    color: white;
                    letter-spacing: -0.02em;
                }

                .graphic-content p {
                    font-size: 1.25rem;
                    opacity: 0.8;
                    font-weight: 300;
                }

                .mountain-svg {
                    position: absolute;
                    bottom: 0;
                    left: 0;
                    width: 100%;
                    height: 60%;
                    z-index: 1;
                    transform-origin: bottom;
                }

                .login-form-side {
                    flex: 1;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    padding: 2rem;
                    position: relative;
                    z-index: 2;
                    background: white;
                    box-shadow: -20px 0 25px -5px rgb(0 0 0 / 0.1);
                }

                .login-card {
                    width: 100%;
                    max-width: 440px;
                    padding: 2rem 1rem;
                }

                .login-header {
                    text-align: center;
                    margin-bottom: 2.5rem;
                }

                .logo-badge {
                    width: 64px;
                    height: 64px;
                    background: var(--primary-light);
                    color: var(--primary);
                    border-radius: 18px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    margin: 0 auto 1.5rem;
                    box-shadow: 0 10px 15px -3px var(--primary-light);
                }

                .login-header h2 {
                    font-size: 1.75rem;
                    font-weight: 700;
                    color: var(--text-primary);
                    margin-bottom: 0.5rem;
                }

                .login-header p {
                    color: var(--text-secondary);
                    font-size: 0.9375rem;
                }

                .login-form {
                    display: flex;
                    flex-direction: column;
                    gap: 1.5rem;
                }

                .input-group {
                    display: flex;
                    flex-direction: column;
                    gap: 0.5rem;
                }

                .input-group label {
                    font-size: 0.875rem;
                    font-weight: 600;
                    color: var(--text-primary);
                }

                .input-wrapper {
                    position: relative;
                }

                .input-icon {
                    position: absolute;
                    left: 14px;
                    top: 50%;
                    transform: translateY(-50%);
                    color: var(--text-muted);
                    transition: color 0.2s;
                }

                .input-wrapper input {
                    width: 100%;
                    padding: 0.875rem 1rem 0.875rem 2.75rem;
                    border: 2px solid var(--border);
                    border-radius: var(--radius);
                    font-size: 1rem;
                    outline: none;
                    transition: all 0.2s;
                    background: #f8fafc;
                }

                .input-wrapper input:focus {
                    border-color: var(--primary);
                    background: white;
                    box-shadow: 0 0 0 4px var(--primary-light);
                }

                .input-wrapper input:focus + .input-icon {
                    color: var(--primary);
                }

                .error-message {
                    background: var(--error-bg);
                    color: var(--error);
                    padding: 1rem;
                    border-radius: var(--radius);
                    font-size: 0.875rem;
                    display: flex;
                    align-items: center;
                    gap: 0.75rem;
                    font-weight: 500;
                }

                .login-btn {
                    width: 100%;
                    padding: 1rem;
                    margin-top: 1rem;
                    font-size: 1rem;
                    border-radius: var(--radius);
                    box-shadow: 0 4px 14px 0 rgba(152, 50, 150, 0.39);
                }
                
                .login-btn:hover {
                    transform: translateY(-2px);
                    box-shadow: 0 6px 20px rgba(152, 50, 150, 0.39);
                }
            `}</style>
        </div>
    );
}
