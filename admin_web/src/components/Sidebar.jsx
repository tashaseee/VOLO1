import React from 'react';
import { NavLink } from 'react-router-dom';
import {
    LayoutDashboard,
    Users,
    Calendar,
    UserCheck,
    LogOut,
    Building2,
    ShieldCheck
} from 'lucide-react';

export default function Sidebar({ onLogout }) {
    const navItems = [
        { to: '/', icon: LayoutDashboard, label: 'Обзор', exact: true },
        { to: '/pending', icon: UserCheck, label: 'Заявки организаций' },
        { to: '/users', icon: Users, label: 'Пользователи' },
        { to: '/events', icon: Calendar, label: 'Мероприятия' },
    ];

    return (
        <aside className="sidebar">
            <div className="sidebar-header">
                <div className="logo-container">
                    <ShieldCheck size={28} className="logo-icon" />
                    <div className="logo-text">
                        <span className="logo-title">VOLO</span>
                        <span className="logo-subtitle">Admin Panel</span>
                    </div>
                </div>
            </div>

            <nav className="sidebar-nav">
                {navItems.map((item) => (
                    <NavLink
                        key={item.to}
                        to={item.to}
                        className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}
                    >
                        <item.icon size={20} />
                        <span>{item.label}</span>
                    </NavLink>
                ))}
            </nav>

            <div className="sidebar-footer">
                <div className="sidebar-mountains">
                     <svg viewBox="0 0 280 120" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="none">
                        <defs>
                            <linearGradient id="sidebar-grad1" x1="0%" y1="0%" x2="0%" y2="100%">
                                <stop offset="0%" stopColor="#c55ac3" stopOpacity="0.8" />
                                <stop offset="100%" stopColor="#983296" stopOpacity="1" />
                            </linearGradient>
                            <linearGradient id="sidebar-grad2" x1="0%" y1="0%" x2="0%" y2="100%">
                                <stop offset="0%" stopColor="#da79d8" stopOpacity="0.6" />
                                <stop offset="100%" stopColor="#7a2879" stopOpacity="1" />
                            </linearGradient>
                        </defs>
                        <path fill="url(#sidebar-grad2)" d="M0,120 L0,70 L50,40 L100,80 L160,30 L220,70 L280,45 L280,120 Z" />
                        <path fill="url(#sidebar-grad1)" d="M0,120 L0,90 L60,60 L120,95 L190,45 L250,75 L280,55 L280,120 Z" />
                    </svg>
                </div>
                <div className="user-profile-wrapper">
                    <div className="user-profile">
                        <div className="avatar">AD</div>
                        <div className="user-info">
                            <p className="user-name">Administrator</p>
                            <p className="user-role">System Manager</p>
                        </div>
                    </div>
                    <button onClick={onLogout} className="logout-btn">
                        <LogOut size={18} />
                        <span>Выйти</span>
                    </button>
                </div>
            </div>

            <style jsx="true">{`
        .sidebar {
          width: 280px;
          height: 100vh;
          background: var(--bg-sidebar);
          border-right: 1px solid var(--border);
          display: flex;
          flex-direction: column;
          position: sticky;
          top: 0;
          z-index: 50;
          overflow: hidden;
        }

        .sidebar-header {
          padding: 2rem 1.5rem;
        }

        .logo-container {
          display: flex;
          align-items: center;
          gap: 0.75rem;
        }

        .logo-icon {
          color: var(--primary);
        }

        .logo-text {
          display: flex;
          flex-direction: column;
        }

        .logo-title {
          font-size: 1.25rem;
          font-weight: 800;
          color: var(--text-primary);
          letter-spacing: -0.02em;
          line-height: 1;
        }

        .logo-subtitle {
          font-size: 0.75rem;
          font-weight: 500;
          color: var(--text-secondary);
        }

        .sidebar-nav {
          flex: 1;
          padding: 0.5rem 1rem;
          display: flex;
          flex-direction: column;
          gap: 0.25rem;
          position: relative;
          z-index: 2;
        }

        .nav-link {
          display: flex;
          align-items: center;
          gap: 0.875rem;
          padding: 0.875rem 1rem;
          color: var(--text-secondary);
          text-decoration: none;
          border-radius: var(--radius);
          font-weight: 500;
          font-size: 0.9375rem;
          transition: all 0.2s;
        }

        .nav-link:hover {
          background: #f8fafc;
          color: var(--primary);
          transform: translateX(4px);
        }

        .nav-link.active {
          background: var(--primary-light);
          color: var(--primary);
          font-weight: 600;
        }

        .sidebar-footer {
          position: relative;
          margin-top: auto;
          display: flex;
          flex-direction: column;
        }

        .sidebar-mountains {
          position: absolute;
          bottom: 0;
          left: 0;
          width: 100%;
          height: 120px;
          z-index: 1;
          pointer-events: none;
          opacity: 0.4;
        }
        
        .sidebar-mountains svg {
          width: 100%;
          height: 100%;
          display: block;
        }

        .user-profile-wrapper {
          padding: 1.5rem;
          border-top: 1px solid var(--border);
          position: relative;
          z-index: 2;
          display: flex;
          flex-direction: column;
          gap: 1.25rem;
          background: linear-gradient(to top, rgba(255,255,255,0.95), rgba(255,255,255,0.8));
          backdrop-filter: blur(4px);
        }

        .user-profile {
          display: flex;
          align-items: center;
          gap: 0.75rem;
        }

        .avatar {
          width: 40px;
          height: 40px;
          border-radius: 12px;
          background: var(--primary);
          color: white;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: 700;
          font-size: 0.875rem;
          box-shadow: 0 4px 10px rgba(152, 50, 150, 0.3);
        }

        .user-info {
          display: flex;
          flex-direction: column;
        }

        .user-name {
          font-size: 0.875rem;
          font-weight: 600;
          color: var(--text-primary);
        }

        .user-role {
          font-size: 0.75rem;
          color: var(--text-secondary);
        }

        .logout-btn {
          width: 100%;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 0.75rem;
          padding: 0.75rem 1rem;
          border: 1px solid rgba(239, 68, 68, 0.2);
          background: white;
          color: var(--error);
          border-radius: var(--radius);
          cursor: pointer;
          font-weight: 600;
          font-size: 0.875rem;
          transition: all 0.2s;
        }

        .logout-btn:hover {
          background: var(--error-bg);
          border-color: var(--error);
          transform: translateY(-2px);
        }
      `}</style>
        </aside>
    );
}
