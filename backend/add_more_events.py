import sys
import os
import datetime

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from app.database import SessionLocal
from app.models.event import Event
from app.models.user import User

def add_events():
    db = SessionLocal()
    try:
        # Пытаемся найти пользователя-организатора, если нет берем первого попавшегося или создаем
        org_user = db.query(User).filter(User.role == "organization").first()
        if not org_user:
            org_user = db.query(User).first()

        new_events = [
            Event(
                title="Помощь в приюте для животных 'Верный Друг'",
                description="Приглашаем волонтеров для помощи в выгуле собак, уборке вольеров и социализации животных. Приют переполнен, и нам очень нужны рабочие руки!",
                organizer="Приют Верный Друг",
                organizer_id=org_user.id if org_user else None,
                date_text="18 Мая",
                full_date=datetime.datetime(2026, 5, 18, 10, 0),
                location="пос. Илийский, ул. Заречная 15",
                hours=5,
                category="Социальные",
                image_url="/static/images/dogs.png",
                responsibilities="Выгул собак\nКормление животных\nУборка вольеров\nПомощь с фото для соцсетей",
                benefits="Volo-часы: 5\nСертификат волонтера\nГорячий чай с печеньем\nБезусловная любовь хвостиков",
            ),
            Event(
                title="Озеленение парка Первого Президента",
                description="Масштабная городская акция по высадке 1000 саженцев тянь-шаньской ели. Сделаем город зеленее!",
                organizer="EcoAlmaty",
                organizer_id=org_user.id if org_user else None,
                date_text="21 Мая",
                full_date=datetime.datetime(2026, 5, 21, 9, 0),
                location="Парк им. Первого Президента",
                hours=4,
                category="Экология",
                image_url="/static/images/eco2.jpeg",
                responsibilities="Подготовка лунок\nВысадка саженцев\nПолив растений",
                benefits="Volo-часы: 4\nФирменная кепка EcoAlmaty\nЛанч-бокс\nМного новых знакомств",
            ),
            Event(
                title="Almaty Marathon 2026: Координация на трассе",
                description="Стань частью крупнейшего спортивного события Центральной Азии! Набираем волонтеров на точки питания и питья вдоль трассы марафона.",
                organizer="КФ Смелость Быть Первым",
                organizer_id=org_user.id if org_user else None,
                date_text="1 Июня",
                full_date=datetime.datetime(2026, 6, 1, 6, 0),
                location="Площадь Республики (Старт)",
                hours=8,
                category="Спорт",
                image_url="/static/images/marathon.png",
                responsibilities="Раздача воды и питания бегунам\nНавигация участников\nПоддержка и мотивация спортсменов",
                benefits="Volo-часы: 8\nОфициальная футболка марафона 2026\nМедаль волонтера\nСтипендия (компенсация проезда)\nПитание",
            ),
            Event(
                title="Форум IT-технологий 'Digital Kazakhstan'",
                description="Требуются волонтеры для работы на зонах регистрации, навигации гостей и помощи спикерам на международном IT-форуме.",
                organizer="Astana Hub",
                organizer_id=org_user.id if org_user else None,
                date_text="10 Июня",
                full_date=datetime.datetime(2026, 6, 10, 8, 30),
                location="Дворец Республики",
                hours=10,
                category="Образование",
                image_url="/static/images/it_forum.jpeg",
                responsibilities="Регистрация участников (выдача бейджей)\nСопровождение VIP-гостей и спикеров\nРассадка зрителей в зале",
                benefits="Volo-часы: 10\nСертификат\nДоступ к выступлениям спикеров\nПитание кофе-брейки\nШанс для нетворкинга в IT",
            ),
            Event(
                title="Обучение пенсионеров цифровой грамотности",
                description="Проект по помощи пожилым людям в освоении смартфонов, приложения eGov, банкинга и мессенджеров.",
                organizer="Фонд 'Связь Поколений'",
                organizer_id=org_user.id if org_user else None,
                date_text="Каждую субботу",
                full_date=datetime.datetime(2026, 5, 25, 14, 0),
                location="Библиотека им. Жамбыла",
                hours=3,
                category="Образование",
                image_url="/static/images/grandparents.png",
                responsibilities="Объяснять как пользоваться WhatsApp\nУчить оплачивать коммуналку через приложение\nПомогать с получением справок eGov",
                benefits="Volo-часы: 3 за каждое занятие\nБлагодарственное письмо\nОгромный социальный импакт",
            ),
            Event(
                title="Фестиваль современной музыки 'Voice of Asia'",
                description="Возрождение легендарного фестиваля на Медео! Ищем самых энергичных волонтеров для помощи бэкстейдж и координации зрителей.",
                organizer="Medeo Fest",
                organizer_id=org_user.id if org_user else None,
                date_text="15 Июля",
                full_date=datetime.datetime(2026, 7, 15, 16, 0),
                location="ВСК 'Медеу'",
                hours=12,
                category="Культура",
                image_url="/static/images/music_fest.jpeg",
                responsibilities="Проверка билетов\nНавигация по зонам на катке\nБэкстейдж-помощь артистам",
                benefits="Volo-часы: 12\nБесплатный вход на зоны фестиваля\nГрандиозная атмосфера\nТрансфер туда/обратно",
            ),
        ]

        db.add_all(new_events)
        db.commit()
        print("Успешно добавлено 6 новых разнообразных мероприятий!")
    except Exception as e:
        print(f"Ошибка: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    add_events()
