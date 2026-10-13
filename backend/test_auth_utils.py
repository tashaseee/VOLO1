import unittest
from unittest.mock import AsyncMock, patch

from app.auth_utils import send_verification_email


class TestAuthUtilsEmail(unittest.IsolatedAsyncioTestCase):
    @patch("app.auth_utils._get_mail_conf")
    @patch("app.auth_utils.FastMail")
    @patch("app.auth_utils._use_smtp", return_value=True)
    async def test_send_verification_email_without_attachments(self, _use_smtp_mock, fastmail_cls, _get_mail_conf):
        mail_instance = AsyncMock()
        mail_instance.send_message = AsyncMock()
        fastmail_cls.return_value = mail_instance

        await send_verification_email("user@example.com", "123456")

        mail_instance.send_message.assert_awaited_once()
        message = mail_instance.send_message.await_args.args[0]
        self.assertEqual(message.attachments, [])


if __name__ == "__main__":
    unittest.main()
