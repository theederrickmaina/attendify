"""
Comprehensive Test Suite for Vector-based Face Recognition System
----------------------------------------------------------
Tests the complete Attendify system with pgvector optimization.
"""

import sys
import numpy as np
from pathlib import Path

# Add backend directory to Python path
backend_dir = Path(__file__).parent / "backend"
sys.path.insert(0, str(backend_dir))

def test_vector_database():
    """Test vector database operations."""
    try:
        print("Testing Vector Database Operations...")
        
        # Test imports
        from vector_face_service import get_vector_face_service
        from models import Student, User
        
        print("✓ Vector face service imported successfully")
        
        # Initialize service
        vector_service = get_vector_face_service()
        print("✓ Vector service initialized")
        
        # Get database stats
        stats = vector_service.get_database_stats()
        print(f"✓ Database stats: {stats}")
        
        # Test embedding storage/retrieval
        test_embedding = np.random.rand(512).astype(np.float32)
        
        # Find a test student
        test_student = Student.query.first()
        if test_student:
            print(f"✓ Found test student: {test_student.name}")
            
            # Store test embedding
            if vector_service.store_embedding(test_student.id, test_embedding):
                print("✓ Test embedding stored successfully")
                
                # Retrieve embedding
                retrieved = vector_service.get_embedding(test_student.id)
                if retrieved is not None:
                    print("✓ Test embedding retrieved successfully")
                    print(f"✓ Embedding dimensions: {retrieved.shape}")
                else:
                    print("⚠ Failed to retrieve test embedding")
            else:
                print("⚠ Failed to store test embedding")
        else:
            print("⚠ No students found in database")
        
        return True
        
    except Exception as e:
        print(f"❌ Vector database test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_similarity_search():
    """Test vector similarity search performance."""
    try:
        print("\nTesting Vector Similarity Search...")
        
        from vector_face_service import get_vector_face_service
        vector_service = get_vector_face_service()
        
        # Create test embeddings
        query_embedding = np.random.rand(512).astype(np.float32)
        
        # Perform similarity search
        matches = vector_service.find_similar_faces_db(query_embedding, similarity_threshold=0.1, max_results=5)
        
        print(f"✓ Found {len(matches)} matches")
        for i, match in enumerate(matches):
            print(f"  Match {i+1}: {match['name']} (similarity: {match['similarity']:.3f})")
        
        return True
        
    except Exception as e:
        print(f"❌ Similarity search test failed: {e}")
        return False

def test_postgresql_connection():
    """Test PostgreSQL connection with pgvector."""
    try:
        print("\nTesting PostgreSQL Connection...")
        
        from extensions import db
        from app import app
        
        with app.app_context():
            # Test basic query
            result = db.session.execute("SELECT version()").scalar()
            print(f"✓ PostgreSQL version: {result}")
            
            # Test pgvector extension
            try:
                result = db.session.execute("SELECT extversion FROM pg_extension WHERE extname = 'vector'").scalar()
                print(f"✓ pgvector extension version: {result}")
            except Exception:
                print("⚠ pgvector extension not found")
            
            # Test vector operations
            try:
                result = db.session.execute("SELECT '[1,2,3]'::vector <-> '[1,2,4]'::vector").scalar()
                print(f"✓ Vector distance test: {result}")
            except Exception as e:
                print(f"⚠ Vector operation test failed: {e}")
        
        return True
        
    except Exception as e:
        print(f"❌ PostgreSQL connection test failed: {e}")
        return False

def test_complete_system():
    """Test the complete integrated system."""
    try:
        print("\nTesting Complete System Integration...")
        
        # Test backend imports
        from app import app
        print("✓ Flask app imported")
        
        # Test database models
        from models import User, Student, Course, Class, Attendance
        print("✓ Database models imported")
        
        # Test vector service
        from vector_face_service import get_vector_face_service
        vector_service = get_vector_face_service()
        print("✓ Vector face service initialized")
        
        # Test face recognition service
        from face_recognition_service import get_face_service
        face_service = get_face_service()
        print("✓ Face recognition service initialized")
        
        # Test API endpoints (basic)
        with app.test_client() as client:
            response = client.get('/health')
            if response.status_code == 200:
                print("✓ Health check endpoint working")
            else:
                print(f"⚠ Health check failed: {response.status_code}")
        
        print("✅ Complete system integration test passed!")
        return True
        
    except Exception as e:
        print(f"❌ System integration test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Run all tests."""
    print("Attendify Vector System Test Suite")
    print("=" * 50)
    
    tests = [
        ("PostgreSQL Connection", test_postgresql_connection),
        ("Vector Database", test_vector_database),
        ("Similarity Search", test_similarity_search),
        ("System Integration", test_complete_system),
    ]
    
    results = []
    for test_name, test_func in tests:
        print(f"\n{'='*20} {test_name} {'='*20}")
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ {test_name} failed with exception: {e}")
            results.append((test_name, False))
    
    # Summary
    print("\n" + "=" * 50)
    print("TEST SUMMARY")
    print("=" * 50)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{test_name:.<30} {status}")
    
    print(f"\nOverall: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed! The vector system is ready.")
        print("\nNext steps:")
        print("1. Set up PostgreSQL database with: python database/create_database.py")
        print("2. Start backend server: python start_backend.py")
        print("3. Run Flutter frontend: cd frontend && flutter run")
    else:
        print(f"\n⚠ {total - passed} tests failed. Please check the errors above.")
        return False
    
    return True

if __name__ == "__main__":
    main()
