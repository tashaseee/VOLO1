import React, { useEffect, useState } from 'react';
import { fetchStats } from '../api';
import { Users, Calendar, Clock, Building } from 'lucide-react';

export default function StatsPage({ token }) {
    const [stats, setStats] = useState({ volunteers: 0, organizers: 0, events: 0, hours: 0 });
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        loadStats();
    }, []);

    const loadStats = async () => {
        try {
            const data = await fetchStats(token);
            setStats(data);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };

    const StatCard = ({ title, value, icon: Icon, color, bgColor }) => (
        <div className="glass-card" style={{ display: 'flex', alignItems: 'center', gap: '1.5rem' }}>
            <div style={{ padding: '1rem', borderRadius: '12px', background: bgColor, color: color }}>
                <Icon size={32} />
            </div>
            <div>
                <div style={{ fontSize: '0.9rem', color: '#52525B', marginBottom: '0.25rem' }}>{title}</div>
                <div style={{ fontSize: '2rem', fontWeight: 'bold' }}>{value}</div>
            </div>
        </div>
    );

    return (
        <div className="animate-fade-in">
            <h1>Обзор системы</h1>
            <p style={{ marginBottom: '2rem' }}>Ключевые показатели платформы VOLO</p>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '1.5rem' }}>
                <StatCard
                    title="Волонтеры"
                    value={stats.volunteers}
                    icon={Users}
                    color="#983296"
                    bgColor="#F3E8FF"
                />
                <StatCard
                    title="Организации"
                    value={stats.organizers}
                    icon={Building}
                    color="#3B82F6"
                    bgColor="#DBEAFE"
                />
                <StatCard
                    title="Мероприятия"
                    value={stats.events}
                    icon={Calendar}
                    color="#10B981"
                    bgColor="#ECFDF5"
                />
                <StatCard
                    title="Часов помощи"
                    value={stats.hours}
                    icon={Clock}
                    color="#F59E0B"
                    bgColor="#FEF3C7"
                />
            </div>
        </div>
    );
}
