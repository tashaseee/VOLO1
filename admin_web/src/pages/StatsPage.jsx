import React, { useEffect, useState } from 'react';
import { fetchStats, fetchActivity, fetchReports } from '../api';
import {
    Users,
    Calendar,
    Clock,
    Building2,
    TrendingUp,
    ArrowUpRight,
    ArrowDownRight,
    Activity,
    FileText,
    X,
    PieChart,
    BarChart,
    CheckCircle,
    AlertTriangle,
    Shield,
    RefreshCw,
    Sparkles,
    Briefcase
} from 'lucide-react';

export default function StatsPage({ token }) {
    const [stats, setStats] = useState({ volunteers: 0, organizers: 0, events: 0, hours: 0, pending_orgs: 0 });
    const [activities, setActivities] = useState([]);
    const [loading, setLoading] = useState(true);
    const [reportsData, setReportsData] = useState(null);
    const [showReports, setShowReports] = useState(false);
    const [refreshing, setRefreshing] = useState(false);

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        setRefreshing(true);
        try {
            const [statsData, activityData, reportsData] = await Promise.all([
                fetchStats(token),
                fetchActivity(token),
                fetchReports(token).catch(() => null)
            ]);
            setStats(statsData);
            setActivities(activityData);
            if (reportsData) {
                setReportsData(reportsData);
            }
        } catch (e) {
            console.error(e);
            alert("Не удалось загрузить данные: " + e.message);
        } finally {
            setLoading(false);
            setRefreshing(false);
        }
    };

    const StatCard = ({ title, value, icon: Icon, color, trend, trendValue }) => (
        <div className="card stat-card" style={{ display: 'flex', alignItems: 'center', gap: '1.5rem', padding: '1.5rem', background: 'white' }}>
            <div className="icon-box" style={{ background: `${color}0F`, color: color, padding: '0.85rem', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon size={24} />
            </div>
            <div style={{ flex: 1 }}>
                <p style={{ fontSize: '0.8125rem', color: 'var(--text-secondary)', fontWeight: '600', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '4px' }}>{title}</p>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem' }}>
                    <h3 style={{ fontSize: '1.75rem', fontWeight: '800', marginTop: '0.25rem', color: 'var(--text-primary)', fontFamily: "'Outfit', sans-serif" }}>{value}</h3>
                    {trend && (
                        <span style={{
                            fontSize: '0.75rem',
                            fontWeight: '700',
                            color: trend === 'up' ? 'var(--success)' : 'var(--error)',
                            display: 'inline-flex',
                            alignItems: 'center',
                            background: trend === 'up' ? 'var(--success-bg)' : 'var(--error-bg)',
                            padding: '2px 6px',
                            borderRadius: '6px'
                        }}>
                            {trend === 'up' ? <ArrowUpRight size={12} /> : <ArrowDownRight size={12} />}
                            {trendValue}
                        </span>
                    )}
                </div>
            </div>
        </div>
    );

    const getTimeAgo = (dateStr) => {
        const date = new Date(dateStr);
        const now = new Date();
        const diffInMs = now - date;
        const diffInMins = Math.floor(diffInMs / (1000 * 60));
        const diffInHours = Math.floor(diffInMins / 60);
        const diffInDays = Math.floor(diffInHours / 24);

        if (diffInMins < 1) return 'только что';
        if (diffInMins < 60) return `${diffInMins} мин назад`;
        if (diffInHours < 24) return `${diffInHours} ч назад`;
        return `${diffInDays} дн назад`;
    };

    if (loading) {
        return (
            <div style={{ padding: '4rem 2rem', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: '1.5rem', height: '80vh' }}>
                <div className="animate-spin" style={{ width: '40px', height: '40px', border: '3px solid var(--border)', borderTopColor: 'var(--primary)', borderRadius: '50%' }}></div>
                <p style={{ fontWeight: '600', color: 'var(--text-secondary)', fontSize: '1.1rem' }}>Загрузка аналитики платформы...</p>
            </div>
        );
    }

    return (
        <div className="animate-slide-in" style={{ paddingBottom: '3rem' }}>
            {/* Header Area */}
            <header style={{ marginBottom: '2.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'linear-gradient(135deg, var(--primary), var(--primary-dark))', color: 'white', width: '48px', height: '48px', borderRadius: '14px', boxShadow: '0 8px 20px rgba(152, 50, 150, 0.25)' }}>
                        <Shield size={24} />
                    </div>
                    <div>
                        <h1 style={{ fontSize: '2.1rem', fontWeight: '800', letterSpacing: '-0.02em', background: 'linear-gradient(135deg, var(--text-primary) 30%, var(--primary) 100%)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>Панель управления</h1>
                        <p className="page-description" style={{ fontSize: '0.9rem', color: 'var(--text-secondary)', margin: '4px 0 0 0', fontWeight: '500' }}>Аналитические показатели и верификация в реальном времени</p>
                    </div>
                </div>
                <div style={{ display: 'flex', gap: '1rem' }}>
                    <button className="btn btn-outline" disabled={refreshing} onClick={loadData} style={{ width: '44px', height: '44px', padding: 0 }}>
                        <RefreshCw size={18} className={refreshing ? 'animate-spin' : ''} />
                    </button>
                    <button className="btn btn-outline" onClick={() => setShowReports(true)} style={{ background: 'white', fontWeight: '700' }}>
                        <FileText size={18} />
                        Официальный отчет
                    </button>
                </div>
            </header>

            {/* Glowing Welcome Banner */}
            <div className="card" style={{
                background: 'linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%)',
                color: 'white',
                border: 'none',
                marginBottom: '2.5rem',
                padding: '2.5rem',
                position: 'relative',
                overflow: 'hidden',
                boxShadow: 'var(--shadow-lg)',
                borderRadius: '24px'
            }}>
                <div style={{ position: 'relative', zIndex: 2, maxWidth: '650px' }}>
                    <div style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', background: 'rgba(255, 255, 255, 0.15)', padding: '4px 10px', borderRadius: '30px', fontSize: '0.75rem', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '1rem', border: '1px solid rgba(255, 255, 255, 0.2)' }}>
                        <Sparkles size={12} />
                        Система безопасности VOLO
                    </div>
                    <h2 style={{ fontSize: '2rem', fontWeight: '800', marginBottom: '0.75rem', color: 'white', letterSpacing: '-0.02em', lineHeight: '1.2' }}>Добро пожаловать в админ-панель VOLO!</h2>
                    <p style={{ opacity: 0.9, fontSize: '0.95rem', lineHeight: '1.6', fontWeight: '500' }}>
                        Здесь вы можете модерировать организации, контролировать строгое выполнение правил безопасности волонтерского труда и просматривать расширенную аналитику платформы в реальном времени.
                    </p>
                </div>
                {/* Embedded SVG graphic representation */}
                <div style={{ position: 'absolute', bottom: -20, right: -20, width: '350px', height: '140%', opacity: 0.12, pointerEvents: 'none' }}>
                     <svg viewBox="0 0 280 120" xmlns="http://www.w3.org/2000/svg" style={{ width: '100%', height: '100%' }}>
                        <path fill="#ffffff" d="M0,120 L0,70 L50,40 L100,80 L160,30 L220,70 L280,45 L280,120 Z" />
                    </svg>
                </div>
            </div>

            {/* Core Stats Grid */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '1.5rem', marginBottom: '2.5rem' }}>
                <StatCard
                    title="Всего волонтеров"
                    value={stats.volunteers}
                    icon={Users}
                    color="#983296"
                    trend="up"
                    trendValue="+12%"
                />
                <StatCard
                    title="Организации"
                    value={stats.organizers}
                    icon={Building2}
                    color="#3b82f6"
                    trend="up"
                    trendValue="+5%"
                />
                <StatCard
                    title="Создано событий"
                    value={stats.events}
                    icon={Calendar}
                    color="#10b981"
                    trend="up"
                    trendValue="+8%"
                />
                <StatCard
                    title="Часов помощи"
                    value={stats.hours}
                    icon={Clock}
                    color="#f59e0b"
                    trend="up"
                    trendValue="+24%"
                />
            </div>

            {/* Expanded Analytics directly on StatsPage (Russian: Больше данных сразу видно) */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))', gap: '2rem', marginBottom: '2.5rem' }}>
                {/* Category distribution widget */}
                <div className="card" style={{ display: 'flex', flexDirection: 'column', background: 'white', padding: '2rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
                        <div>
                            <h2 style={{ fontSize: '1.125rem', fontWeight: '800', color: 'var(--text-primary)' }}>Распределение по категориям</h2>
                            <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', margin: '2px 0 0 0', fontWeight: '500' }}>Количество активных мероприятий в разрезе направлений</p>
                        </div>
                        <div style={{ padding: '0.65rem', background: 'var(--primary-light)', borderRadius: '12px', color: 'var(--primary)' }}>
                            <PieChart size={20} />
                        </div>
                    </div>
                    {reportsData ? (
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem', flex: 1, justifyContent: 'center' }}>
                            {reportsData.category_distribution.map(cat => {
                                const total = reportsData.total_stats.active_events || 1;
                                const pct = Math.round((cat.value / total) * 100);
                                return (
                                    <div key={cat.name} style={{ display: 'flex', alignItems: 'center', gap: '1.25rem' }}>
                                        <span style={{ fontSize: '0.85rem', width: '110px', fontWeight: '700', color: 'var(--text-primary)' }}>{cat.name}</span>
                                        <div style={{ flex: 1, height: '8px', background: '#f1f5f9', borderRadius: '4px', overflow: 'hidden' }}>
                                            <div style={{
                                                width: `${pct}%`,
                                                height: '100%',
                                                background: 'linear-gradient(90deg, var(--primary), var(--primary-light))',
                                                borderRadius: '4px'
                                            }}></div>
                                        </div>
                                        <div style={{ display: 'flex', gap: '8px', width: '50px', justifyContent: 'flex-end', fontSize: '0.85rem' }}>
                                            <span style={{ fontWeight: '800', color: 'var(--text-primary)' }}>{cat.value}</span>
                                            <span style={{ color: 'var(--text-muted)', fontWeight: '600' }}>{pct}%</span>
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    ) : (
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '3rem 0', color: 'var(--text-muted)' }}>Аналитика распределения не найдена</div>
                    )}
                </div>

                {/* Hours analysis widget */}
                <div className="card" style={{ display: 'flex', flexDirection: 'column', background: 'white', padding: '2rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
                        <div>
                            <h2 style={{ fontSize: '1.125rem', fontWeight: '800', color: 'var(--text-primary)' }}>Накопленные часы помощи</h2>
                            <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', margin: '2px 0 0 0', fontWeight: '500' }}>Суммарные волонтерские часы по категориям</p>
                        </div>
                        <div style={{ padding: '0.65rem', background: '#DBEAFE', borderRadius: '12px', color: '#3B82F6' }}>
                            <BarChart size={20} />
                        </div>
                    </div>
                    {reportsData ? (
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem', flex: 1, justifyContent: 'center' }}>
                            {reportsData.hours_by_category.map(cat => {
                                const totalHours = stats.hours || 1;
                                const pct = Math.round((cat.hours / totalHours) * 100);
                                return (
                                    <div key={cat.category} style={{ display: 'flex', alignItems: 'center', gap: '1.25rem' }}>
                                        <span style={{ fontSize: '0.85rem', width: '110px', fontWeight: '700', color: 'var(--text-primary)' }}>{cat.category}</span>
                                        <div style={{ flex: 1, height: '8px', background: '#f1f5f9', borderRadius: '4px', overflow: 'hidden' }}>
                                            <div style={{
                                                width: `${pct}%`,
                                                height: '100%',
                                                background: 'linear-gradient(90deg, #3b82f6, #93c5fd)',
                                                borderRadius: '4px'
                                            }}></div>
                                        </div>
                                        <div style={{ display: 'flex', gap: '8px', width: '60px', justifyContent: 'flex-end', fontSize: '0.85rem' }}>
                                            <span style={{ fontWeight: '800', color: 'var(--text-primary)' }}>{cat.hours}ч</span>
                                            <span style={{ color: 'var(--text-muted)', fontWeight: '600' }}>{pct}%</span>
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    ) : (
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '3rem 0', color: 'var(--text-muted)' }}>Аналитика часов не найдена</div>
                    )}
                </div>
            </div>

            {/* Bottom Grid: Recent Activity & Requires Attention */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))', gap: '2rem' }}>
                {/* Column 1: Recent Activity */}
                <div className="card" style={{ display: 'flex', flexDirection: 'column', background: 'white', padding: '2rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
                        <div>
                            <h2 style={{ fontSize: '1.125rem', fontWeight: '800', color: 'var(--text-primary)' }}>Недавняя активность</h2>
                            <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', margin: '2px 0 0 0', fontWeight: '500' }}>События системы в реальном времени</p>
                        </div>
                        <div style={{ padding: '0.5rem', background: 'var(--primary-light)', borderRadius: '50%', color: 'var(--primary)' }}>
                            <Activity size={20} />
                        </div>
                    </div>
                    <div className="activity-list" style={{ flex: 1, overflowY: 'auto', paddingRight: '0.5rem', maxHeight: '380px' }}>
                        {activities.length === 0 ? (
                            <div style={{ padding: '3rem 0', textAlign: 'center', opacity: 0.6 }}>
                                <Activity size={40} style={{ margin: '0 auto 1rem', opacity: 0.5 }} />
                                <p className="empty-text">Активности пока нет</p>
                            </div>
                        ) : activities.map((item, idx) => (
                            <div key={idx} style={{
                                display: 'flex',
                                gap: '1rem',
                                padding: '1rem 0',
                                borderBottom: idx === activities.length - 1 ? 'none' : '1px solid var(--border)',
                                transition: 'all 0.2s',
                            }} className="activity-item">
                                <div style={{
                                    width: '36px',
                                    height: '36px',
                                    borderRadius: '10px',
                                    background: item.type === 'registration' ? 'var(--primary-light)' : item.type === 'application' ? '#DBEAFE' : 'var(--success-bg)',
                                    color: item.type === 'registration' ? 'var(--primary)' : item.type === 'application' ? '#3B82F6' : 'var(--success)',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    fontSize: '0.875rem',
                                    fontWeight: '700',
                                    boxShadow: '0 2px 6px rgba(0,0,0,0.03)'
                                }}>
                                    {item.user ? item.user[0].toUpperCase() : '?'}
                                </div>
                                <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
                                    <p style={{ fontSize: '0.875rem', color: 'var(--text-primary)', margin: 0, lineHeight: '1.4' }}>
                                        <span style={{ fontWeight: '700' }}>{item.user}</span> {item.action}
                                    </p>
                                    <p style={{ fontSize: '0.7rem', color: 'var(--text-muted)', marginTop: '2px', fontWeight: '600' }}>{getTimeAgo(item.time)}</p>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Column 2: Requires Attention */}
                <div className="card" style={{ display: 'flex', flexDirection: 'column', background: 'white', padding: '2rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                        <div>
                            <h2 style={{ fontSize: '1.125rem', fontWeight: '800', color: 'var(--text-primary)' }}>Требует внимания</h2>
                            <p style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', margin: '2px 0 0 0', fontWeight: '500' }}>Критические действия модерации</p>
                        </div>
                        <div style={{ padding: '0.5rem', background: 'var(--warning-bg)', borderRadius: '50%', color: 'var(--warning)' }}>
                            <AlertTriangle size={20} />
                        </div>
                    </div>

                    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                        <div style={{ 
                            background: 'rgba(255, 251, 235, 0.6)', 
                            border: '1px solid rgba(245, 158, 11, 0.25)', 
                            padding: '1.25rem', 
                            borderRadius: '16px', 
                            display: 'flex', 
                            alignItems: 'center', 
                            gap: '1.25rem',
                            transition: 'all 0.3s'
                        }} className="attention-item">
                            <div style={{ background: 'var(--warning)', color: 'white', padding: '10px', borderRadius: '10px', boxShadow: '0 4px 10px rgba(245, 158, 11, 0.3)' }}>
                                <Building2 size={20} />
                            </div>
                            <div>
                                <p style={{ fontSize: '0.95rem', fontWeight: '700', color: '#b45309', margin: 0 }}>Регистрации организаций</p>
                                <p style={{ fontSize: '0.8rem', color: '#d97706', marginTop: '3px', margin: 0 }}>Ожидают проверки: <span style={{fontWeight: '800'}}>{stats.pending_orgs || 0}</span></p>
                            </div>
                        </div>

                        <div style={{ 
                            background: 'rgba(236, 253, 245, 0.6)', 
                            border: '1px solid rgba(16, 185, 129, 0.25)', 
                            padding: '1.25rem', 
                            borderRadius: '16px', 
                            display: 'flex', 
                            alignItems: 'center', 
                            gap: '1.25rem',
                            transition: 'all 0.3s'
                        }} className="attention-item">
                            <div style={{ background: 'var(--success)', color: 'white', padding: '10px', borderRadius: '10px', boxShadow: '0 4px 10px rgba(16, 185, 129, 0.3)' }}>
                                <CheckCircle size={20} />
                            </div>
                            <div>
                                <p style={{ fontSize: '0.95rem', fontWeight: '700', color: '#047857', margin: 0 }}>Завершенные мероприятия</p>
                                <p style={{ fontSize: '0.8rem', color: '#059669', marginTop: '3px', margin: 0 }}>Нужно начислить часы волонтерам</p>
                            </div>
                        </div>
                    </div>

                    <div style={{ 
                        marginTop: 'auto', 
                        textAlign: 'center', 
                        padding: '2.5rem 1.5rem 0.5rem',
                        background: 'radial-gradient(ellipse at top, rgba(152, 50, 150, 0.05) 0%, transparent 70%)'
                    }}>
                        <div style={{
                            width: '64px',
                            height: '64px',
                            borderRadius: '20px',
                            background: 'linear-gradient(135deg, var(--primary-light), white)',
                            color: 'var(--primary)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            margin: '0 auto 1.25rem',
                            boxShadow: '0 10px 25px rgba(152, 50, 150, 0.12)',
                            transform: 'rotate(-5deg)'
                        }}>
                            <TrendingUp size={30} />
                        </div>
                        <h3 style={{ fontSize: '1.05rem', marginBottom: '0.5rem', fontWeight: '800' }}>Рост сообщества</h3>
                        <p style={{ color: 'var(--text-secondary)', fontSize: '0.85rem', lineHeight: '1.5', margin: 0 }}>
                            За последнюю неделю активность выросла на <strong>15%</strong>. Продолжайте в том же духе!
                        </p>
                    </div>
                </div>
            </div>

            <style jsx="true">{`
                .activity-item:hover {
                    transform: translateX(5px);
                    background: rgba(243, 232, 255, 0.1);
                    border-radius: var(--radius-sm);
                    padding-left: 0.5rem;
                    padding-right: 0.5rem;
                }
                .attention-item:hover {
                    transform: translateY(-2px);
                    box-shadow: 0 5px 15px rgba(0,0,0,0.03);
                }
                .modal-overlay {
                    position: fixed;
                    inset: 0;
                    background: rgba(15, 23, 42, 0.4);
                    backdrop-filter: blur(8px);
                    z-index: 100;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    padding: 2rem;
                }
                .modal-content {
                    background: rgba(255, 255, 255, 0.95);
                    width: 100%;
                    border-radius: var(--radius-lg);
                    box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
                    position: relative;
                    overflow: hidden;
                    border: 1px solid rgba(255, 255, 255, 0.5);
                }
                .close-btn {
                    position: absolute;
                    top: 1.5rem;
                    right: 1.5rem;
                    background: white;
                    border: 1px solid var(--border);
                    border-radius: 50%;
                    width: 36px;
                    height: 36px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    cursor: pointer;
                    color: var(--text-secondary);
                    transition: all 0.2s;
                    z-index: 10;
                }
                .close-btn:hover {
                    color: var(--error);
                    background: var(--error-bg);
                    border-color: rgba(239, 68, 68, 0.2);
                    transform: rotate(90deg);
                }
                .modal-header {
                    padding: 2.5rem 2.5rem 2rem;
                    background: linear-gradient(135deg, rgba(243, 232, 255, 0.5) 0%, rgba(255, 255, 255, 0) 100%);
                    border-bottom: 1px solid var(--border);
                    display: flex;
                    align-items: center;
                    gap: 1.5rem;
                }
                .modal-avatar {
                    width: 64px;
                    height: 64px;
                    border-radius: 20px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    box-shadow: 0 8px 16px rgba(152, 50, 150, 0.15);
                }
                .modal-title-area h2 {
                    font-size: 1.5rem;
                    font-weight: 800;
                    margin-bottom: 0.25rem;
                    color: var(--text-primary);
                }
                .modal-title-area p {
                    color: var(--text-secondary);
                    font-size: 0.875rem;
                    font-weight: 500;
                }
                .modal-body {
                    padding: 2.5rem;
                    max-height: calc(100vh - 200px);
                    overflow-y: auto;
                }
                .animate-spin {
                    animation: spin 1s linear infinite;
                }
                @keyframes spin {
                    from { transform: rotate(0deg); }
                    to { transform: rotate(360deg); }
                }
            `}</style>
            
            {/* Reports Modal */}
            {showReports && (
                <div className="modal-overlay" onClick={() => setShowReports(false)}>
                    <div className="modal-content animate-slide-in" onClick={e => e.stopPropagation()} style={{ maxWidth: '850px' }}>
                        <button className="close-btn" onClick={() => setShowReports(false)}>
                            <X size={20} />
                        </button>

                        <div className="modal-header">
                            <div className="modal-avatar" style={{ background: 'var(--primary)', color: 'white' }}>
                                <FileText size={32} />
                            </div>
                            <div className="modal-title-area">
                                <h2>Официальный отчет системы</h2>
                                <p>Сформировано: {new Date().toLocaleString()}</p>
                            </div>
                        </div>

                        <div className="modal-body">
                            {!reportsData ? (
                                <div style={{ padding: '4rem 2rem', textAlign: 'center', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem' }}>
                                    <div className="animate-pulse" style={{ width: '48px', height: '48px', borderRadius: '50%', background: 'var(--primary-light)', color: 'var(--primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                        <Activity size={24} />
                                    </div>
                                    <p style={{ fontSize: '1.25rem', fontWeight: '600', color: 'var(--text-secondary)' }}>Генерация данных аналитики...</p>
                                </div>
                            ) : (
                                <div style={{ display: 'flex', flexDirection: 'column', gap: '2.5rem' }}>
                                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem' }}>
                                        <div className="card" style={{ background: 'rgba(255, 255, 255, 0.5)', padding: '2rem' }}>
                                            <h3 style={{ fontSize: '1rem', marginBottom: '1.5rem', color: 'var(--text-primary)', fontWeight: '700' }}>Распределение по категориям</h3>
                                            <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                                                {reportsData.category_distribution.map(cat => (
                                                    <div key={cat.name} style={{ display: 'flex', alignItems: 'center', gap: '1.25rem' }}>
                                                        <span style={{ fontSize: '0.875rem', width: '90px', fontWeight: '500' }}>{cat.name}</span>
                                                        <div style={{ flex: 1, height: '8px', background: 'rgba(226, 232, 240, 0.8)', borderRadius: '4px', overflow: 'hidden' }}>
                                                            <div style={{
                                                                width: `${(cat.value / (reportsData.total_stats.active_events || 1)) * 100}%`,
                                                                height: '100%',
                                                                background: 'linear-gradient(90deg, var(--primary), var(--primary-light))',
                                                                borderRadius: '4px'
                                                            }}></div>
                                                        </div>
                                                        <span style={{ fontSize: '0.875rem', fontWeight: '800', width: '30px', textAlign: 'right' }}>{cat.value}</span>
                                                    </div>
                                                ))}
                                            </div>
                                        </div>

                                        <div className="card" style={{ background: 'rgba(255, 255, 255, 0.5)', padding: '2rem' }}>
                                            <h3 style={{ fontSize: '1rem', marginBottom: '1.5rem', color: 'var(--text-primary)', fontWeight: '700' }}>Часы по категориям</h3>
                                            <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                                                {reportsData.hours_by_category.map(cat => (
                                                    <div key={cat.category} style={{ display: 'flex', alignItems: 'center', gap: '1.25rem' }}>
                                                        <span style={{ fontSize: '0.875rem', width: '90px', fontWeight: '500' }}>{cat.category}</span>
                                                        <div style={{ flex: 1, height: '8px', background: 'rgba(226, 232, 240, 0.8)', borderRadius: '4px', overflow: 'hidden' }}>
                                                            <div style={{
                                                                width: `${(cat.hours / (stats.hours || 1)) * 100}%`,
                                                                height: '100%',
                                                                background: 'linear-gradient(90deg, #3b82f6, #93c5fd)',
                                                                borderRadius: '4px'
                                                            }}></div>
                                                        </div>
                                                        <span style={{ fontSize: '0.875rem', fontWeight: '800', width: '40px', textAlign: 'right' }}>{cat.hours}ч</span>
                                                    </div>
                                                ))}
                                            </div>
                                        </div>
                                    </div>

                                    <div className="card" style={{ 
                                        background: 'linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%)', 
                                        color: 'white',
                                        border: 'none',
                                        boxShadow: '0 20px 40px -10px rgba(152, 50, 150, 0.4)'
                                    }}>
                                        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', textAlign: 'center', padding: '1rem 0' }}>
                                            <div>
                                                <p style={{ opacity: 0.8, fontSize: '0.875rem', fontWeight: '500', marginBottom: '0.5rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Ожидают</p>
                                                <h4 style={{ fontSize: '2.5rem', fontWeight: '800' }}>{reportsData.total_stats.pending_orgs}</h4>
                                            </div>
                                            <div style={{ borderLeft: '1px solid rgba(255,255,255,0.2)', borderRight: '1px solid rgba(255,255,255,0.2)' }}>
                                                <p style={{ opacity: 0.8, fontSize: '0.875rem', fontWeight: '500', marginBottom: '0.5rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Всего ивентов</p>
                                                <h4 style={{ fontSize: '2.5rem', fontWeight: '800' }}>{reportsData.total_stats.active_events}</h4>
                                            </div>
                                            <div>
                                                <p style={{ opacity: 0.8, fontSize: '0.875rem', fontWeight: '500', marginBottom: '0.5rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Заявок</p>
                                                <h4 style={{ fontSize: '2.5rem', fontWeight: '800' }}>{reportsData.total_stats.completed_applications}</h4>
                                            </div>
                                        </div>
                                    </div>

                                    <button className="btn btn-primary" onClick={() => window.print()} style={{ alignSelf: 'center', padding: '1rem 2rem', fontSize: '1rem' }}>
                                        <FileText size={20} />
                                        Экспорт в PDF
                                    </button>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
