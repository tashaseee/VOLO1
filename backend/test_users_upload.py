import unittest

from app.api.users import _is_supported_image_upload


class DummyUploadFile:
    def __init__(self, filename: str, content_type: str | None):
        self.filename = filename
        self.content_type = content_type


class TestUsersUpload(unittest.TestCase):
    def test_png_file_is_accepted_when_content_type_is_missing(self):
        file = DummyUploadFile("template.png", None)

        self.assertTrue(_is_supported_image_upload(file))

    def test_pdf_file_is_rejected(self):
        file = DummyUploadFile("template.pdf", None)

        self.assertFalse(_is_supported_image_upload(file))


if __name__ == "__main__":
    unittest.main()
