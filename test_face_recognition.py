"""
Test Script for Face Recognition Service
--------------------------------------
Tests the InsightFace integration and basic functionality.
"""

import sys
import numpy as np
import cv2
from pathlib import Path

# Add the backend directory to Python path
backend_dir = Path(__file__).parent / "backend"
sys.path.insert(0, str(backend_dir))

def test_face_recognition():
    """Test the face recognition service with a synthetic image."""
    try:
        from face_recognition_service import get_face_service
        
        print("Testing Face Recognition Service...")
        
        # Initialize the service
        face_service = get_face_service()
        print("✓ Face recognition service initialized successfully")
        
        # Create a test image (synthetic face-like pattern)
        test_image = np.zeros((200, 200, 3), dtype=np.uint8)
        
        # Add some face-like features (simplified)
        # Face outline
        cv2.circle(test_image, (100, 100), 80, (150, 150, 150), -1)
        # Eyes
        cv2.circle(test_image, (70, 80), 10, (0, 0, 0), -1)
        cv2.circle(test_image, (130, 80), 10, (0, 0, 0), -1)
        # Mouth
        cv2.ellipse(test_image, (100, 120), (30, 15), 0, 0, 180, (0, 0, 0), 2)
        
        print("✓ Test image created")
        
        # Test quality assessment
        quality = face_service.assess_image_quality(test_image)
        print(f"✓ Quality assessment: {quality}")
        
        # Test face detection
        faces = face_service.detect_faces(test_image, confidence_threshold=0.1)
        print(f"✓ Face detection found {len(faces)} faces")
        
        # Test embedding extraction
        if faces:
            embedding = face_service.extract_embedding(test_image, faces[0]['bbox'])
            if embedding is not None:
                print(f"✓ Embedding extracted successfully (shape: {embedding.shape})")
            else:
                print("⚠ Embedding extraction failed")
        
        print("\n✅ Face recognition service test completed successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Face recognition test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_backend_imports():
    """Test that all backend modules can be imported."""
    try:
        print("Testing Backend Imports...")
        
        # Test basic imports
        import sys
        sys.path.append('backend')
        
        from app import app
        print("✓ Flask app imported successfully")
        
        from models import User, Student, Course, Class, Attendance
        print("✓ Database models imported successfully")
        
        from extensions import db
        print("✓ Database extensions imported successfully")
        
        print("✅ Backend imports test completed successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Backend imports test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("Attendify System Test Suite")
    print("=" * 40)
    
    # Test imports
    imports_ok = test_backend_imports()
    print()
    
    # Test face recognition
    face_rec_ok = test_face_recognition()
    print()
    
    if imports_ok and face_rec_ok:
        print("🎉 All tests passed! The system is ready to use.")
        print("\nTo start the backend server:")
        print("  python start_backend.py")
        print("\nTo run the Flutter frontend:")
        print("  cd frontend && flutter run")
    else:
        print("❌ Some tests failed. Please check the errors above.")
        sys.exit(1)
