"""
Image handling utilities for the BIDR Product Management Service.
"""

import os
import uuid
from pathlib import Path
from typing import List, Optional, Tuple
from django.core.files.uploadedfile import InMemoryUploadedFile
from django.core.files.storage import default_storage
from django.conf import settings
from PIL import Image
import logging

logger = logging.getLogger(__name__)


def save_uploaded_images(
    images: List[InMemoryUploadedFile], 
    subfolder: str = 'product_requests',
    max_size: Tuple[int, int] = (1024, 1024)
) -> List[str]:
    """
    Save uploaded images to media storage and return list of URLs.
    
    Args:
        images: List of uploaded image files
        subfolder: Subfolder within media directory to store images
        max_size: Maximum size tuple (width, height) for image resizing
        
    Returns:
        List of image URLs that can be stored in database
    """
    if not images:
        return []
    
    saved_urls = []
    
    for i, image_file in enumerate(images):
        try:
            # Generate unique filename
            original_name = getattr(image_file, 'name', f'image_{i}')
            file_extension = Path(original_name).suffix.lower()
            
            # Ensure valid image extension
            if file_extension not in ['.jpg', '.jpeg', '.png', '.gif', '.webp']:
                file_extension = '.jpg'  # Default to jpg
            
            unique_filename = f"{uuid.uuid4()}{file_extension}"
            relative_path = f"{subfolder}/{unique_filename}"
            
            # Resize image if needed
            resized_image_file = resize_image_if_needed(image_file, max_size)
            
            # Save the file using Django's default storage
            saved_path = default_storage.save(relative_path, resized_image_file)
            
            # Generate URL - this works both for local development and production
            if hasattr(default_storage, 'url'):
                image_url = default_storage.url(saved_path)
            else:
                # Fallback for local development
                image_url = f"{settings.MEDIA_URL}{saved_path}"
            
            saved_urls.append(image_url)
            logger.info(f"Successfully saved image: {saved_path} -> {image_url}")
            
        except Exception as e:
            logger.error(f"Failed to save image {i}: {str(e)}")
            # Continue processing other images even if one fails
            continue
    
    return saved_urls


def resize_image_if_needed(
    image_file: InMemoryUploadedFile, 
    max_size: Tuple[int, int] = (1024, 1024)
) -> InMemoryUploadedFile:
    """
    Resize image if it exceeds maximum dimensions.
    
    Args:
        image_file: Uploaded image file
        max_size: Maximum size tuple (width, height)
        
    Returns:
        Original or resized image file
    """
    try:
        # Open image with PIL
        image = Image.open(image_file)
        
        # Check if resize is needed
        if image.width <= max_size[0] and image.height <= max_size[1]:
            # Reset file pointer and return original
            image_file.seek(0)
            return image_file
        
        # Resize maintaining aspect ratio
        image.thumbnail(max_size, Image.Resampling.LANCZOS)
        
        # Convert RGBA to RGB if needed (for JPEG)
        if image.mode == 'RGBA':
            # Create white background
            background = Image.new('RGB', image.size, (255, 255, 255))
            background.paste(image, mask=image.split()[-1])  # Use alpha channel as mask
            image = background
        
        # Save resized image to memory
        from io import BytesIO
        import django.core.files.uploadedfile as upload_file
        
        output_buffer = BytesIO()
        image_format = 'JPEG'  # Default to JPEG for smaller file size
        image.save(output_buffer, format=image_format, quality=85, optimize=True)
        output_buffer.seek(0)
        
        # Create new InMemoryUploadedFile
        resized_file = upload_file.InMemoryUploadedFile(
            output_buffer,
            field_name=image_file.field_name,
            name=f"{Path(image_file.name).stem}.jpg",  # Change extension to .jpg
            content_type='image/jpeg',
            size=output_buffer.tell(),
            charset=None
        )
        
        logger.info(f"Resized image from {image.width}x{image.height} to fit within {max_size}")
        return resized_file
        
    except Exception as e:
        logger.error(f"Failed to resize image: {str(e)}")
        # Return original file if resize fails
        image_file.seek(0)
        return image_file


def validate_image_file(image_file: InMemoryUploadedFile) -> bool:
    """
    Validate that uploaded file is a valid image.
    
    Args:
        image_file: Uploaded file to validate
        
    Returns:
        True if valid image, False otherwise
    """
    try:
        # Check content type
        if not image_file.content_type or not image_file.content_type.startswith('image/'):
            return False
        
        # Check file size (max 10MB)
        max_size = 10 * 1024 * 1024  # 10MB
        if image_file.size > max_size:
            logger.warning(f"Image file too large: {image_file.size} bytes")
            return False
        
        # Try to open with PIL to verify it's a valid image
        image_file.seek(0)
        image = Image.open(image_file)
        image.verify()  # Verify it's a valid image
        image_file.seek(0)  # Reset file pointer
        
        return True
        
    except Exception as e:
        logger.error(f"Image validation failed: {str(e)}")
        return False


def delete_image(image_url: str) -> bool:
    """
    Delete an image from storage given its URL.
    
    Args:
        image_url: URL of the image to delete
        
    Returns:
        True if successful, False otherwise
    """
    try:
        # Extract relative path from URL
        if image_url.startswith(settings.MEDIA_URL):
            relative_path = image_url.replace(settings.MEDIA_URL, '')
            
            if default_storage.exists(relative_path):
                default_storage.delete(relative_path)
                logger.info(f"Successfully deleted image: {relative_path}")
                return True
            else:
                logger.warning(f"Image file not found: {relative_path}")
                return False
        
        return False
        
    except Exception as e:
        logger.error(f"Failed to delete image {image_url}: {str(e)}")
        return False


def cleanup_unused_images(used_image_urls: List[str], subfolder: str = 'product_requests') -> int:
    """
    Clean up unused images from storage.
    
    Args:
        used_image_urls: List of image URLs currently in use
        subfolder: Subfolder to clean up
        
    Returns:
        Number of images deleted
    """
    try:
        deleted_count = 0
        
        # Get all files in the subfolder
        if default_storage.exists(subfolder):
            directories, files = default_storage.listdir(subfolder)
            
            for filename in files:
                file_path = f"{subfolder}/{filename}"
                file_url = f"{settings.MEDIA_URL}{file_path}"
                
                # If this file URL is not in the used list, delete it
                if file_url not in used_image_urls:
                    if default_storage.delete(file_path):
                        deleted_count += 1
                        logger.info(f"Deleted unused image: {file_path}")
        
        return deleted_count
        
    except Exception as e:
        logger.error(f"Failed to cleanup unused images: {str(e)}")
        return 0