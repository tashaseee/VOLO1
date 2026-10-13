import bcrypt
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig, MessageType
from pydantic import EmailStr
import os
from dotenv import load_dotenv

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), "..", ".env"))

# Remove CryptContext as it causes issues with newer bcrypt versions
# pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def verify_password(plain_password, hashed_password):
    # Bcrypt limit 72 bytes
    if len(plain_password.encode("utf-8")) > 72:
        plain_password = plain_password.encode("utf-8")[:72].decode(
            "utf-8", errors="ignore"
        )

    # Ensure bytes
    plain_bytes = plain_password.encode("utf-8")
    hash_bytes = hashed_password.encode("utf-8")

    return bcrypt.checkpw(plain_bytes, hash_bytes)


def get_password_hash(password):
    if len(password.encode("utf-8")) > 72:
        password = password.encode(
            "utf-8")[:72].decode("utf-8", errors="ignore")

    pwd_bytes = password.encode("utf-8")
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(pwd_bytes, salt).decode("utf-8")


# Email Configuration - с отключенной проверкой SSL
conf = ConnectionConfig(
    MAIL_USERNAME=os.getenv("MAIL_USERNAME", "volo.2025.kz@gmail.com"),
    MAIL_PASSWORD=os.getenv("MAIL_PASSWORD", "lgul vwtr wkmj nsbe"),
    MAIL_FROM=os.getenv("MAIL_FROM", "volo.2025.kz@gmail.com"),
    MAIL_PORT=587,
    MAIL_SERVER="smtp.gmail.com",
    MAIL_STARTTLS=True,
    MAIL_SSL_TLS=False,
    USE_CREDENTIALS=True,
    VALIDATE_CERTS=False,  # ОТКЛЮЧАЕМ проверку SSL
    TIMEOUT=10,
)


async def send_verification_email(email: EmailStr, code: str):
    # В режиме разработки просто печатаем код
    # if os.getenv("ENVIRONMENT", "development") == "development":
    #     print(f"\n{'='*60}")
    #     print(f"📧 DEV EMAIL - НЕ ОТПРАВЛЕНО НА СЕРВЕР")
    #     print(f"📨 Для: {email}")
    #     print(f"🔢 Код верификации: {code}")
    #     print(f"{'='*60}\n")
    #     return

    # Продакшен код (не будет выполняться пока ENVIRONMENT=development)
    html = f"""
    <h3>Ваш код верификации VOLO</h3>
    <p>Для завершения регистрации, пожалуйста, введите этот код в приложении:</p>
    <h1>{code}</h1>
    <p>Если вы не запрашивали этот код, проигнорируйте это письмо.</p>
    """

    message = MessageSchema(
        subject="Код подтверждения регистрации VOLO",
        recipients=[email],
        body=html,
        subtype=MessageType.html,
    )

    fm = FastMail(conf)
    try:
        await fm.send_message(message)
        print(f"✅ Email отправлен на {email}")
    except Exception as e:
        print(f"❌ Ошибка отправки email: {e}")


async def send_approval_email(email: EmailStr):
    html = """
    <div style="font-family: 'Poppins', sans-serif; color: #1F2937; max-width: 600px; margin: 0 auto; border: 1px solid #F3F4F6; border-radius: 16px; padding: 32px;">
        <h2 style="color: #983296; text-align: center;">Добро пожаловать в VOLO! 🎉</h2>
        <p>Уважаемый партнер,</p>
        <p>Мы рады сообщить, что ваша заявка на регистрацию организации в системе <strong>VOLO</strong> была успешно одобрена администратором.</p>
        <div style="background-color: #F9FAFB; padding: 20px; border-radius: 12px; margin: 24px 0;">
            <p style="margin: 0; font-weight: 600; color: #111827;">Теперь вы можете войти в свой профиль, используя ваш email и пароль.</p>
        </div>

        <h3 style="color: #111827; border-bottom: 2px solid #F3F4F6; padding-bottom: 8px;">Правила пользования и условия:</h3>
        <ul style="line-height: 1.6;">
            <li><strong>Ответственность:</strong> Организация несет полную ответственность за достоверность информации о мероприятиях и безопасность волонтеров.</li>
            <li><strong>Этика:</strong> Уважительное отношение ко всем участникам. Дискриминация и нарушение прав недопустимы.</li>
            <li><strong>Верификация:</strong> Просим своевременно подтверждать участие волонтеров и проставлять часы.</li>
            <li><strong>Условия:</strong> Входя в систему, вы подтверждаете согласие с публичной офертой и правилами платформы VOLO.</li>
        </ul>

        <p style="margin-top: 32px;">Желаем вам успешных проектов и плодотворного сотрудничества!</p>
        <p style="color: #6B7280; font-size: 14px; margin-top: 24px; border-top: 1px solid #F3F4F6; padding-top: 16px; text-align: center;">
            С уважением,<br>Команда VOLO
        </p>
    </div>
    """

    message = MessageSchema(
        subject="Ваша организация одобрена в VOLO",
        recipients=[email],
        body=html,
        subtype=MessageType.html,
    )

    fm = FastMail(conf)
    try:
        await fm.send_message(message)
        print(f"✅ Email об одобрении отправлен на {email}")
    except Exception as e:
        print(f"❌ Ошибка отправки email об одобрении: {e}")


async def send_reset_email(email: EmailStr, code: str):
    # В режиме разработки просто печатаем код
    # if os.getenv("ENVIRONMENT", "development") == "development":
    #     print(f"\n{'='*60}")
    #     print(f"📧 DEV EMAIL - НЕ ОТПРАВЛЕНО НА СЕРВЕР")
    #     print(f"📨 Для: {email}")
    #     print(f"🔢 Код сброса пароля: {code}")
    #     print(f"{'='*60}\n")
    #     return

    # Продакшен код
    html = f"""
    <h3>VOLO - волонтерство в Казахстане</h3>
    <p>Ваш код для сброса пароля:</p>
    <h1>{code}</h1>
    <p>Если вы не запрашивали сброс пароля, проигнорируйте это письмо.</p>
    """

    message = MessageSchema(
        subject="Восстановление пароля VOLO",
        recipients=[email],
        body=html,
        subtype=MessageType.html,
    )

    fm = FastMail(conf)
    try:
        await fm.send_message(message)
        print(f"✅ Email отправлен на {email}")
    except Exception as e:
        print(f"❌ Ошибка отправки email: {e}")


async def send_application_status_email(
        email: EmailStr,
        event_name: str,
        status: str):
    subject = f"Обновление заявки на мероприятие '{event_name}'"

    if status == "approved":
        status_text = "ОДОБРЕНА! 🎉"
        body_text = f"Поздравляем! Ваша заявка на участие в мероприятии <b>{event_name}</b> была одобрена организатором."
        color = "#10B981"  # Green
    elif status == "rejected":
        status_text = "ОТКЛОНЕНА"
        body_text = f"К сожалению, ваша заявка на участие в мероприятии <b>{event_name}</b> была отклонена."
        color = "#EF4444"  # Red
    else:
        status_text = "ОБНОВЛЕНА"
        body_text = f"Статус вашей заявки на мероприятие <b>{event_name}</b> изменился на: {status}."
        color = "#3B82F6"  # Blue

    html = f"""
    <div style="font-family: 'Poppins', sans-serif; color: #1F2937; max-width: 600px; margin: 0 auto; border: 1px solid #F3F4F6; border-radius: 16px; padding: 32px;">
        <h2 style="color: {color}; text-align: center;">Заявка {status_text}</h2>
        <p>Здравствуйте,</p>
        <p>{body_text}</p>

        <div style="background-color: #F9FAFB; padding: 20px; border-radius: 12px; margin: 24px 0;">
            <p style="margin: 0; font-weight: 600; color: #111827;">Проверьте статус в приложении в разделе "Мои заявки".</p>
        </div>

        <p style="color: #6B7280; font-size: 14px; margin-top: 24px; border-top: 1px solid #F3F4F6; padding-top: 16px; text-align: center;">
            С уважением,<br>Команда VOLO
        </p>
    </div>
    """

    message = MessageSchema(
        subject=subject,
        recipients=[email],
        body=html,
        subtype=MessageType.html)

    fm = FastMail(conf)
    try:
        await fm.send_message(message)
        print(f"✅ Email о статусе отправлен на {email}")
    except Exception as e:
        print(f"❌ Ошибка отправки email о статусе: {e}")
