import unittest
import json
from backend.app import app
from backend.extensions import db
from backend.models import User, Student

class AttendifyTestCase(unittest.TestCase):
    def setUp(self):
        """Set up test client and in-memory database."""
        app.config['TESTING'] = True
        app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
        app.config['JWT_SECRET_KEY'] = 'test-secret'
        self.client = app.test_client()
        
        with app.app_context():
            db.create_all()
            # Create a test admin
            admin = User(
                username='admin_test',
                role='admin',
                password_hash='pbkdf2:sha256:testpass',
                consent_given=True
            )
            db.session.add(admin)
            db.session.commit()

    def tearDown(self):
        """Clean up database."""
        with app.app_context():
            db.session.remove()
            db.drop_all()

    def test_login_success(self):
        """Test valid login returns token."""
        response = self.client.post('/api/login', json={
            'username': 'admin_test',
            'password': 'testpass'
        })
        data = json.loads(response.data)
        self.assertEqual(response.status_code, 200)
        self.assertIn('access_token', data)

    def test_login_failure(self):
        """Test invalid login."""
        response = self.client.post('/api/login', json={
            'username': 'admin_test',
            'password': 'wrongpassword'
        })
        self.assertEqual(response.status_code, 401)

    def test_enroll_requires_consent(self):
        """Test enrollment fails without consent."""
        # Based on app.py, enrollment seems to be open but checks consent field
        response = self.client.post('/api/enroll', json={
            'name': 'Test Student',
            'reg_no': 'TS001',
            'course': 'CS',
            'year': 1,
            'semester': 1,
            'facial_image_base64': 'dGVzdA==', # 'test' base64
            'consent': False
        })
        # app.py returns 403 for consent_required
        self.assertEqual(response.status_code, 403)
        self.assertIn('consent_required', str(response.data))

    def test_health_check(self):
        """Test if the app is running."""
        response = self.client.get('/health')
        self.assertEqual(response.status_code, 200)

if __name__ == '__main__':
    unittest.main()
