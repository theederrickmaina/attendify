"""
Advanced Facial Recognition Service using InsightFace
----------------------------------------------------
Provides high-accuracy face detection, embedding extraction, and recognition
using state-of-the-art deep learning models.
"""

import cv2
import numpy as np
import insightface
from typing import List, Tuple, Optional, Dict, Any
import logging
import os
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FaceRecognitionService:
    """
    High-performance face recognition service using InsightFace.
    Supports multiple face detection models and provides accurate embeddings.
    """
    
    def __init__(self, model_name: str = 'buffalo_l', det_size: Tuple[int, int] = (640, 640)):
        """
        Initialize face recognition service.
        
        Args:
            model_name: Name of the InsightFace model to use
            det_size: Detection size for face detection
        """
        self.model_name = model_name
        self.det_size = det_size
        
        try:
            # Initialize InsightFace app for detection and analysis
            self.app = insightface.app.FaceAnalysis(name=model_name)
            self.app.prepare(ctx_id=0, det_size=det_size)  # Use GPU if available, else CPU
            
            # Note: We'll use the app's built-in embedding extraction
            # instead of loading a separate recognizer model
            self.recognizer = None  # Not needed with InsightFace app
            
            logger.info(f"Face recognition service initialized with model: {model_name}")
            
        except Exception as e:
            logger.error(f"Failed to initialize face recognition service: {e}")
            raise RuntimeError(f"Face recognition initialization failed: {e}")
    
    def detect_faces(self, image: np.ndarray, confidence_threshold: float = 0.5) -> List[Dict[str, Any]]:
        """
        Detect faces in an image.
        
        Args:
            image: Input image as numpy array (BGR format)
            confidence_threshold: Minimum confidence for face detection
            
        Returns:
            List of detected faces with bounding boxes and landmarks
        """
        try:
            faces = self.app.get(image)
            
            detected_faces = []
            for face in faces:
                if face.det_score >= confidence_threshold:
                    detected_faces.append({
                        'bbox': face.bbox.astype(int).tolist(),  # [x1, y1, x2, y2]
                        'confidence': float(face.det_score),
                        'landmarks': face.kps.astype(int).tolist() if hasattr(face, 'kps') else None,
                        'age': int(face.age) if hasattr(face, 'age') else None,
                        'gender': face.gender if hasattr(face, 'gender') else None,
                        'embedding': face.embedding.tolist() if hasattr(face, 'embedding') else None
                    })
            
            logger.info(f"Detected {len(detected_faces)} faces")
            return detected_faces
            
        except Exception as e:
            logger.error(f"Face detection failed: {e}")
            return []
    
    def extract_embedding(self, image: np.ndarray, face_bbox: Optional[List[int]] = None) -> Optional[np.ndarray]:
        """
        Extract face embedding from an image.
        
        Args:
            image: Input image as numpy array (BGR format)
            face_bbox: Optional face bounding box [x1, y1, x2, y2]
            
        Returns:
            Face embedding as numpy array or None if extraction fails
        """
        try:
            if face_bbox is not None:
                # Crop face region
                x1, y1, x2, y2 = face_bbox
                face_img = image[y1:y2, x1:x2]
            else:
                face_img = image
            
            # Use InsightFace app to get face with embedding
            faces = self.app.get(face_img)
            
            if faces and len(faces) > 0:
                # Use the first detected face
                face = faces[0]
                if hasattr(face, 'embedding') and face.embedding is not None:
                    embedding = np.array(face.embedding)
                    # Normalize embedding
                    norm = np.linalg.norm(embedding)
                    if norm > 0:
                        embedding = embedding / norm
                    return embedding
            
            return None
            
        except Exception as e:
            logger.error(f"Embedding extraction failed: {e}")
            return None
    
    def compare_faces(self, embedding1: np.ndarray, embedding2: np.ndarray, threshold: float = 0.6) -> Tuple[bool, float]:
        """
        Compare two face embeddings.
        
        Args:
            embedding1: First face embedding
            embedding2: Second face embedding
            threshold: Similarity threshold for matching
            
        Returns:
            Tuple of (is_match, similarity_score)
        """
        try:
            # Calculate cosine similarity
            similarity = np.dot(embedding1, embedding2)
            
            is_match = similarity >= threshold
            return is_match, float(similarity)
            
        except Exception as e:
            logger.error(f"Face comparison failed: {e}")
            return False, 0.0
    
    def find_best_match(self, probe_embedding: np.ndarray, 
                       known_embeddings: List[np.ndarray], 
                       threshold: float = 0.6) -> Tuple[Optional[int], float]:
        """
        Find the best matching face from known embeddings.
        
        Args:
            probe_embedding: Face embedding to match
            known_embeddings: List of known face embeddings
            threshold: Minimum similarity threshold
            
        Returns:
            Tuple of (best_match_index, similarity_score) or (None, 0) if no match
        """
        try:
            if not known_embeddings:
                return None, 0.0
            
            best_score = 0.0
            best_index = None
            
            for i, known_embedding in enumerate(known_embeddings):
                is_match, similarity = self.compare_faces(probe_embedding, known_embedding, threshold)
                
                if similarity > best_score:
                    best_score = similarity
                    best_index = i
            
            if best_score >= threshold:
                return best_index, best_score
            
            return None, 0.0
            
        except Exception as e:
            logger.error(f"Face matching failed: {e}")
            return None, 0.0
    
    def assess_image_quality(self, image: np.ndarray) -> Dict[str, Any]:
        """
        Assess image quality for face recognition.
        
        Args:
            image: Input image as numpy array
            
        Returns:
            Dictionary with quality metrics
        """
        try:
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            
            # Calculate blur using Laplacian variance
            blur_score = float(cv2.Laplacian(gray, cv2.CV_64F).var())
            
            # Calculate brightness
            brightness = float(gray.mean())
            
            # Calculate contrast (standard deviation)
            contrast = float(gray.std())
            
            # Detect faces to check if at least one face is present
            faces = self.detect_faces(image, confidence_threshold=0.3)
            face_detected = len(faces) > 0
            
            # Overall quality assessment
            quality_ok = (
                blur_score > 100.0 and  # Not too blurry
                50.0 <= brightness <= 200.0 and  # Good lighting
                contrast > 30.0 and  # Good contrast
                face_detected  # At least one face
            )
            
            return {
                'blur_score': blur_score,
                'brightness': brightness,
                'contrast': contrast,
                'face_detected': face_detected,
                'quality_ok': quality_ok,
                'faces_found': len(faces)
            }
            
        except Exception as e:
            logger.error(f"Quality assessment failed: {e}")
            return {
                'blur_score': 0.0,
                'brightness': 0.0,
                'contrast': 0.0,
                'face_detected': False,
                'quality_ok': False,
                'faces_found': 0
            }

# Global instance for the service
_face_service = None

def get_face_service() -> FaceRecognitionService:
    """
    Get or create the global face recognition service instance.
    
    Returns:
        FaceRecognitionService instance
    """
    global _face_service
    
    if _face_service is None:
        _face_service = FaceRecognitionService()
    
    return _face_service

def decode_base64_image(base64_string: str) -> Optional[np.ndarray]:
    """
    Decode a base64 string to OpenCV image.
    
    Args:
        base64_string: Base64 encoded image string
        
    Returns:
        Decoded image as numpy array or None if decoding fails
    """
    try:
        import base64
        
        # Remove data URL prefix if present
        if ',' in base64_string:
            base64_string = base64_string.split(',')[1]
        
        # Decode base64
        img_data = base64.b64decode(base64_string)
        
        # Convert to numpy array
        nparr = np.frombuffer(img_data, np.uint8)
        
        # Decode to OpenCV format
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            logger.error("Failed to decode image from base64")
            return None
        
        return image
        
    except Exception as e:
        logger.error(f"Base64 image decoding failed: {e}")
        return None
