import React from 'react';
import { NavLink } from 'react-router-dom';
import { LayoutDashboard, Users, Calendar, UserPlus, LogOut } from 'lucide-react';

export default function Sidebar({ onLogout }) {
    const linkStyle = ({ isActive }) => ({
        display: 'flex',
        alignItems: 'center',
        gap: '1rem',
        padding: '1rem 1.5rem',
        color: isActive ? '#983296' : '#52525B',
        background: isActive ? '#F3E8FF' : 'transparent',
        textDecoration: 'none',
        borderRadius: '8px',
        fontWeight: isActive ? 600 : 500,
        marginBottom: '0.5rem',
        transition: 'all 0.2s ease'
    });

    return (
        <div style={{
            width: '280px',
            background: 'white',
            borderRight: '1px solid #E0E0E0',
            display: 'flex',
            flexDirection: 'column',
            height: '100vh',
            position: 'sticky',
            top: 0
        }}>
            <div style={{ padding: '2rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <img src="/logo.svg" alt="VOLO" style={{ height: '32px' }} />
                <span style={{ fontSize: '1.25rem', fontWeight: 'bold' }}>Admin</span>
            </div>

            <nav style={{ flex: 1, padding: '0 1rem' }}>
                <NavLink to="/" style={linkStyle}>
                    <LayoutDashboard size={20} />
                    Обзор
                </NavLink>
                <NavLink to="/pending" style={linkStyle}>
                    <UserPlus size={20} />
                    Заявки организаций
                </NavLink>
                <NavLink to="/users" style={linkStyle}>
                    <Users size={20} />
                    Пользователи
                </NavLink>
                <NavLink to="/events" style={linkStyle}>
                    <Calendar size={20} />
                    Мероприятия
                </NavLink>
            </nav>

            <div style={{ padding: '1rem' }}>
                <button
                    onClick={onLogout}
                    style={{
                        width: '100%',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '1rem',
                        padding: '1rem 1.5rem',
                        border: 'none',
                        background: '#FEF2F2',
                        color: '#EF4444',
                        borderRadius: '8px',
                        cursor: 'pointer',
                        fontWeight: 500
                    }}
                >
                    <LogOut size={20} />
                    Выход
                </button>
            </div>
        </div>
    );
}
