"""
Liveness Detection Service
---------------------------
Implements blink detection and head movement analysis to prevent photo spoofing.
"""

import cv2
import numpy as np
from typing import List, Dict, Any, Tuple, Optional
import logging
import time
from collections import deque

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class LivenessDetector:
    """
    Advanced liveness detection using blink detection and head movement analysis.
    Prevents spoofing with photos or videos.
    """
    
    def __init__(self):
        """Initialize liveness detector."""
        self.blink_threshold = 0.25  # Eye aspect ratio threshold for blink
        self.consecutive_frames = 3  # Consecutive frames for blink detection
        self.movement_threshold = 0.02  # Minimum movement threshold
        self.frame_history = deque(maxlen=10)  # Store recent frames
        
        # Eye aspect ratio landmarks (68-point model)
        self.left_eye_start, self.left_eye_end = 36, 41
        self.right_eye_start, self.right_eye_end = 42, 47
        
        logger.info("Liveness detector initialized")
    
    def detect_blink(self, landmarks: np.ndarray) -> bool:
        """
        Detect blink using eye aspect ratio.
        
        Args:
            landmarks: Facial landmarks (68, 2)
            
        Returns:
            True if blink detected, False otherwise
        """
        try:
            # Calculate eye aspect ratio for left eye
            left_eye = landmarks[self.left_eye_start:self.left_eye_end + 1]
            left_ear = self._calculate_eye_aspect_ratio(left_eye)
            
            # Calculate eye aspect ratio for right eye
            right_eye = landmarks[self.right_eye_start:self.right_eye_end + 1]
            right_ear = self._calculate_eye_aspect_ratio(right_eye)
            
            # Average eye aspect ratio
            ear = (left_ear + right_ear) / 2.0
            
            # Check for blink
            return ear < self.blink_threshold
            
        except Exception as e:
            logger.error(f"Blink detection failed: {e}")
            return False
    
    def _calculate_eye_aspect_ratio(self, eye: np.ndarray) -> float:
        """Calculate eye aspect ratio."""
        try:
            # Compute the euclidean distances between the two sets of vertical eye landmarks
            A = np.linalg.norm(eye[1] - eye[5])
            B = np.linalg.norm(eye[2] - eye[4])
            
            # Compute the euclidean distance between the horizontal eye landmark
            C = np.linalg.norm(eye[0] - eye[3])
            
            # Compute the eye aspect ratio
            ear = (A + B) / (2.0 * C)
            
            return ear
            
        except Exception:
            return 0.0
    
    def detect_head_movement(self, current_frame: np.ndarray, previous_frame: np.ndarray) -> float:
        """
        Detect head movement between frames.
        
        Args:
            current_frame: Current frame
            previous_frame: Previous frame
            
        Returns:
            Movement magnitude (0.0 to 1.0)
        """
        try:
            # Convert to grayscale
            current_gray = cv2.cvtColor(current_frame, cv2.COLOR_BGR2GRAY)
            previous_gray = cv2.cvtColor(previous_frame, cv2.COLOR_BGR2GRAY)
            
            # Calculate optical flow
            flow = cv2.calcOpticalFlowPyrLK(
                previous_gray, current_gray, 
                np.array([[100, 100]], dtype=np.float32).reshape(-1, 1, 2),
                None
            )[0]
            
            if flow is not None and len(flow) > 0:
                # Calculate movement magnitude
                movement = np.linalg.norm(flow[0])
                return min(movement / 100.0, 1.0)  # Normalize to 0-1
            
            return 0.0
            
        except Exception as e:
            logger.error(f"Head movement detection failed: {e}")
            return 0.0
    
    def analyze_liveness_sequence(self, frames: List[np.ndarray], landmarks_list: List[np.ndarray]) -> Dict[str, Any]:
        """
        Analyze a sequence of frames for liveness.
        
        Args:
            frames: List of video frames
            landmarks_list: List of facial landmarks for each frame
            
        Returns:
            Liveness analysis results
        """
        try:
            if len(frames) < 5:
                return {
                    'is_live': False,
                    'confidence': 0.0,
                    'reason': 'Insufficient frames for analysis',
                    'blinks_detected': 0,
                    'movement_detected': False
                }
            
            # Blink detection
            blinks_detected = 0
            for landmarks in landmarks_list:
                if self.detect_blink(landmarks):
                    blinks_detected += 1
            
            # Head movement detection
            movement_scores = []
            for i in range(1, len(frames)):
                movement = self.detect_head_movement(frames[i], frames[i-1])
                movement_scores.append(movement)
            
            avg_movement = np.mean(movement_scores) if movement_scores else 0.0
            movement_detected = avg_movement > self.movement_threshold
            
            # Liveness decision
            blink_confidence = min(blinks_detected / len(frames), 1.0)
            movement_confidence = min(avg_movement / self.movement_threshold, 1.0) if movement_detected else 0.0
            
            # Combined confidence
            overall_confidence = (blink_confidence * 0.6) + (movement_confidence * 0.4)
            
            # Decision logic
            is_live = (
                blinks_detected >= 1 and  # At least one blink
                movement_detected and      # Some head movement
                overall_confidence >= 0.3  # Minimum confidence
            )
            
            return {
                'is_live': is_live,
                'confidence': overall_confidence,
                'reason': self._get_liveness_reason(blinks_detected, movement_detected, overall_confidence),
                'blinks_detected': blinks_detected,
                'movement_detected': movement_detected,
                'avg_movement': avg_movement,
                'blink_confidence': blink_confidence,
                'movement_confidence': movement_confidence
            }
            
        except Exception as e:
            logger.error(f"Liveness analysis failed: {e}")
            return {
                'is_live': False,
                'confidence': 0.0,
                'reason': f'Analysis failed: {str(e)}',
                'blinks_detected': 0,
                'movement_detected': False
            }
    
    def _get_liveness_reason(self, blinks: int, movement: bool, confidence: float) -> str:
        """Get human-readable liveness assessment reason."""
        if confidence >= 0.7:
            return "Strong evidence of live person"
        elif confidence >= 0.4:
            return "Moderate evidence of live person"
        elif blinks == 0:
            return "No blinks detected - possible photo"
        elif not movement:
            return "No head movement detected - possible photo"
        else:
            return "Insufficient liveness indicators"
    
    def quick_liveness_check(self, image: np.ndarray, landmarks: Optional[np.ndarray] = None) -> Dict[str, Any]:
        """
        Quick liveness check for single image.
        
        Args:
            image: Input image
            landmarks: Optional facial landmarks
            
        Returns:
            Basic liveness assessment
        """
        try:
            # Basic quality checks that indicate liveness
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            
            # Check for natural lighting variations
            lighting_variance = float(gray.var())
            
            # Check for image compression artifacts (indicates photo)
            compression_score = self._detect_compression_artifacts(image)
            
            # Basic liveness indicators — tuned for single-frame webcam captures
            # Webcams naturally produce some lighting variance (> 100 is realistic)
            natural_lighting = lighting_variance > 100.0
            # Webcam JPEG streams have moderate compression; printed photos are often worse
            low_compression = compression_score < 0.3
            
            confidence = 0.0
            if natural_lighting:
                confidence += 0.5
            if low_compression:
                confidence += 0.3
            
            # Bonus: face color variance (real skin has subtle color variation)
            if len(image.shape) == 3:
                color_std = float(np.std(image, axis=(0, 1)).mean())
                if color_std > 20.0:
                    confidence += 0.2
            
            # Add frame to history for movement detection
            self.frame_history.append(image)
            
            # Check for subtle movements if we have history
            movement_confidence = 0.0
            if len(self.frame_history) >= 2:
                movement = self.detect_head_movement(
                    self.frame_history[-1], 
                    self.frame_history[-2]
                )
                movement_confidence = min(movement / self.movement_threshold, 1.0) * 0.3
                confidence += movement_confidence
            
            # For single-frame checks, be lenient — true liveness requires
            # multi-frame analysis (blink + movement) which is done separately
            return {
                'is_live': confidence >= 0.4,
                'confidence': min(confidence, 1.0),
                'natural_lighting': natural_lighting,
                'low_compression': low_compression,
                'movement_detected': movement_confidence > 0.1,
                'reason': 'Quick liveness assessment'
            }
            
        except Exception as e:
            logger.error(f"Quick liveness check failed: {e}")
            return {
                'is_live': False,
                'confidence': 0.0,
                'reason': f'Check failed: {str(e)}'
            }
    
    def _detect_compression_artifacts(self, image: np.ndarray) -> float:
        """Detect compression artifacts that indicate photo spoofing."""
        try:
            # Convert to grayscale
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            
            # Apply high-pass filter to detect compression artifacts
            kernel = np.array([[-1, -1, -1], [-1, 8, -1], [-1, -1, -1]])
            filtered = cv2.filter2D(gray, -1, kernel)
            
            # Calculate artifact score
            artifact_score = np.mean(np.abs(filtered)) / 255.0
            
            return artifact_score
            
        except Exception:
            return 0.0

# Global instance
_liveness_detector = None

def get_liveness_detector() -> LivenessDetector:
    """Get or create the global liveness detector instance."""
    global _liveness_detector
    
    if _liveness_detector is None:
        _liveness_detector = LivenessDetector()
    
    return _liveness_detector
