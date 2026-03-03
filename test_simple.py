"""
Simple Attendify System Test
---------------------------
Basic functionality test without complex imports.
"""

def test_basic_functionality():
    """Test basic system components."""
    try:
        print("Testing Basic System Components...")
        print("=" * 50)

        # Test 1: Import basic modules
        try:
            import numpy as np
            import cv2
            print("✓ Basic dependencies imported")
        except ImportError as e:
            print(f"❌ Basic import failed: {e}")
            return False

        # Test 2: Test numpy operations
        try:
            arr = np.random.rand(512)
            norm = np.linalg.norm(arr)
            normalized = arr / norm if norm > 0 else arr
            print("✓ NumPy vector operations working")
        except Exception as e:
            print(f"❌ NumPy operations failed: {e}")
            return False

        # Test 3: Test OpenCV basic functionality
        try:
            img = np.zeros((100, 100, 3), dtype=np.uint8)
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            print("✓ OpenCV basic operations working")
        except Exception as e:
            print(f"❌ OpenCV operations failed: {e}")
            return False

        # Test 4: Test FaceNet mock service
        try:
            from backend.facenet_service import FaceNetService
            service = FaceNetService(use_mock=True)
            embedding = service.extract_embedding(img)
            if len(embedding) == 512:
                print("✓ FaceNet mock service working")
            else:
                print(f"⚠ Embedding dimension: {len(embedding)}")
        except Exception as e:
            print(f"❌ FaceNet service failed: {e}")
            return False

        # Test 5: Test Liveness Detection
        try:
            from backend.liveness_detection import get_liveness_detector
            detector = get_liveness_detector()
            result = detector.quick_liveness_check(img)
            print("✓ Liveness detection working")
        except Exception as e:
            print(f"❌ Liveness detection failed: {e}")
            return False

        print("\n🎉 Basic system components test PASSED!")
        print("The core functionality is working correctly.")
        return True

    except Exception as e:
        print(f"❌ Basic functionality test failed: {e}")
        return False

def test_database_connection():
    """Test database connection without complex imports."""
    try:
        print("\nTesting Database Connection...")
        print("=" * 50)

        import os

        # Check if environment is configured
        db_uri = os.getenv("SQLALCHEMY_DATABASE_URI", "")
        if db_uri:
            print(f"✓ Database URI configured: {db_uri[:50]}...")
        else:
            print("⚠ No database URI configured")
            return False

        # Try basic psycopg2 connection
        try:
            import psycopg2
            from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

            # Parse connection details from URI
            # postgresql://user:password@host:port/database
            if "@" in db_uri and "/" in db_uri:
                parts = db_uri.replace("postgresql://", "").split("@")
                credentials = parts[0].split(":")
                host_info = parts[1].split("/")

                user = credentials[0]
                password = credentials[1] if len(credentials) > 1 else ""
                host_port = host_info[0].split(":")
                host = host_port[0]
                port = host_port[1] if len(host_port) > 1 else "5432"
                database = host_info[1]

                conn = psycopg2.connect(
                    host=host,
                    port=port,
                    database=database,
                    user=user,
                    password=password
                )
                conn.close()
                print("✓ Database connection successful")
                return True
            else:
                print("⚠ Invalid database URI format")
                return False

        except ImportError:
            print("⚠ psycopg2 not available")
            return False
        except Exception as e:
            print(f"❌ Database connection failed: {e}")
            return False

    except Exception as e:
        print(f"❌ Database test failed: {e}")
        return False

if __name__ == "__main__":
    print("Attendify Simple System Test")
    print("=" * 50)

    tests = [
        ("Basic Functionality", test_basic_functionality),
        ("Database Connection", test_database_connection),
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
    print("SIMPLE SYSTEM TEST SUMMARY")
    print("=" * 50)

    passed = sum(1 for _, result in results if result)
    total = len(results)

    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{test_name:.<30} {status}")

    print(f"\nOverall: {passed}/{total} tests passed")

    if passed == total:
        print("\n🎉 All basic tests passed!")
        print("The Attendify system core is working correctly.")
        print("\nNext steps:")
        print("1. Install pgvector: Follow the installation guide")
        print("2. Run: python start_backend.py")
        print("3. Test Flutter app: flutter run")
    else:
        print(f"\n⚠ {total - passed} tests failed.")
        print("Check the error messages above for issues.")
