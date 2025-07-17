from flask import Flask, request, jsonify
import cv2
import numpy as np
import pytesseract
import re
from PIL import Image, ImageEnhance, ImageFilter
import requests
from io import BytesIO
import easyocr
import torch
from transformers import BlipProcessor, BlipForConditionalGeneration, CLIPProcessor, CLIPModel
from ultralytics import YOLO
import base64
import json
from collections import defaultdict
import math

app = Flask(__name__)

# AI Models ni yuklash
print("Loading enhanced AI models...")
reader = easyocr.Reader(['ru'])

# BLIP model for image understanding
blip_processor = BlipProcessor.from_pretrained("Salesforce/blip-image-captioning-base")
blip_model = BlipForConditionalGeneration.from_pretrained("Salesforce/blip-image-captioning-base")

# CLIP model for better classification
clip_processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
clip_model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")

# YOLO model for object detection
yolo_model = YOLO('yolov8n.pt')

print("Enhanced AI models loaded successfully!")

# Kolodets (well) uchun maxsus material patterns
KOLODETS_MATERIALS = {
    'concrete_rings': {
        'patterns': [
            r'кольцо\s*(?:кс|жби|бетонное)?\s*(\d+)[-.]?(\d+)?',
            r'кс[-]?(\d+)[-.]?(\d+)?',
            r'жби\s*кольцо\s*(\d+)[-.]?(\d+)?',
            r'бетонное\s*кольцо\s*(\d+)x(\d+)',
            r'ring\s*(\d+)[-.]?(\d+)?',
            r'concrete\s*ring\s*(\d+)[-.]?(\d+)?',
        ],
        'keywords': ['кольцо', 'кс', 'жби', 'бетонное кольцо', 'ring', 'concrete ring'],
        'sizes': ['10-9', '15-9', '20-9', '10-6', '15-6', '20-6'],
        'unit': 'дона',
        'category': 'concrete_elements'
    },
    'concrete_covers': {
        'patterns': [
            r'крышка\s*(?:кс|жби|бетонная)?\s*(\d+)',
            r'плита\s*(?:перекрытия|крышка)?\s*(\d+)',
            r'пкс[-]?(\d+)',
            r'cover\s*(\d+)',
            r'lid\s*(\d+)',
        ],
        'keywords': ['крышка', 'плита перекрытия', 'пкс', 'cover', 'lid'],
        'sizes': ['10', '15', '20'],
        'unit': 'дона',
        'category': 'concrete_elements'
    },
    'bottom_plates': {
        'patterns': [
            r'плита\s*(?:днища|дна|опорная)?\s*(\d+)',
            r'пд[-]?(\d+)',
            r'опорная\s*плита\s*(\d+)',
            r'bottom\s*plate\s*(\d+)',
        ],
        'keywords': ['плита днища', 'пд', 'опорная плита', 'bottom plate'],
        'sizes': ['10', '15', '20'],
        'unit': 'дона',
        'category': 'concrete_elements'
    },
    'pipes': {
        'patterns': [
            r'труба\s*(?:пнд|пэ|стальная|металлическая|водопроводная)?\s*(?:ø|d|диаметр)?\s*(\d+)(?:\s*мм)?',
            r'водопроводная\s*труба\s*(?:ø|d)?\s*(\d+)',
            r'трубопровод\s*(?:ø|d)?\s*(\d+)',
            r'pipe\s*(?:ø|d)?\s*(\d+)',
            r'quvur\s*(?:ø|d)?\s*(\d+)',
        ],
        'keywords': ['труба', 'водопроводная труба', 'трубопровод', 'pipe', 'quvur'],
        'sizes': ['50', '63', '75', '90', '110', '125', '160', '200'],
        'unit': 'метр',
        'category': 'pipes'
    },
    'fittings': {
        'patterns': [
            r'муфта\s*(?:соединительная|пнд)?\s*(?:ø|d)?\s*(\d+)',
            r'тройник\s*(?:пнд|водопроводный)?\s*(?:ø|d)?\s*(\d+)(?:x(\d+))?',
            r'отвод\s*(?:90°|45°)?\s*(?:ø|d)?\s*(\d+)',
            r'переход\s*(?:ø|d)?\s*(\d+)x(\d+)',
            r'заглушка\s*(?:ø|d)?\s*(\d+)',
        ],
        'keywords': ['муфта', 'тройник', 'отвод', 'переход', 'заглушка'],
        'sizes': ['50', '63', '75', '90', '110', '125'],
        'unit': 'дона',
        'category': 'fittings'
    },
    'valves': {
        'patterns': [
            r'задвижка\s*(?:водопроводная|чугунная)?\s*(?:ø|d)?\s*(\d+)',
            r'вентиль\s*(?:водопроводный|запорный)?\s*(?:ø|d)?\s*(\d+)',
            r'кран\s*(?:шаровой|запорный|водопроводный)?\s*(?:ø|d)?\s*(\d+)',
            r'клапан\s*(?:обратный|запорный)?\s*(?:ø|d)?\s*(\d+)',
        ],
        'keywords': ['задвижка', 'вентиль', 'кран', 'клапан'],
        'sizes': ['50', '63', '75', '80', '100', '125'],
        'unit': 'дона',
        'category': 'valves'
    },
    'manholes': {
        'patterns': [
            r'люк\s*(?:чугунный|стальной|канализационный)?\s*(\d+)',
            r'лаз\s*(?:люк)?\s*(\d+)',
            r'крышка\s*люка\s*(\d+)',
            r'manhole\s*(\d+)',
        ],
        'keywords': ['люк', 'лаз', 'крышка люка', 'manhole'],
        'sizes': ['600', '700', '800'],
        'unit': 'дона',
        'category': 'manholes'
    },
    'sealing': {
        'patterns': [
            r'уплотнитель\s*(?:резиновый)?\s*(\d+)',
            r'прокладка\s*(?:резиновая)?\s*(\d+)',
            r'герметик\s*(?:битумный|полимерный)?',
            r'мастика\s*(?:битумная|гидроизоляционная)?',
        ],
        'keywords': ['уплотнитель', 'прокладка', 'герметик', 'мастика'],
        'sizes': ['стандарт'],
        'unit': 'комплект',
        'category': 'sealing'
    }
}

# Kolodets scheme detection keywords
KOLODETS_SCHEME_KEYWORDS = [
    'колодец', 'скважина', 'водопровод', 'канализация', 'дренаж',
    'well', 'water', 'sewage', 'drainage', 'manhole',
    'quduq', 'suv', 'kanalizatsiya', 'drenaj'
]

def ultra_advanced_preprocessing(image):
    """Eng ilg'or preprocessing usullari"""
    processed_images = []
    
    # Original
    processed_images.append(image)
    
    # Convert to PIL for advanced processing
    pil_image = Image.fromarray(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
    
    # 1. Grayscale with different methods
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    processed_images.append(cv2.cvtColor(gray, cv2.COLOR_GRAY2BGR))
    
    # 2. Adaptive histogram equalization
    clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8,8))
    enhanced = clahe.apply(gray)
    processed_images.append(cv2.cvtColor(enhanced, cv2.COLOR_GRAY2BGR))
    
    # 3. Multiple noise reduction
    denoised1 = cv2.fastNlMeansDenoising(gray, h=10)
    processed_images.append(cv2.cvtColor(denoised1, cv2.COLOR_GRAY2BGR))
    
    denoised2 = cv2.bilateralFilter(gray, 9, 75, 75)
    processed_images.append(cv2.cvtColor(denoised2, cv2.COLOR_GRAY2BGR))
    
    # 4. Sharpening with different kernels
    kernel1 = np.array([[-1,-1,-1], [-1,9,-1], [-1,-1,-1]])
    sharpened1 = cv2.filter2D(gray, -1, kernel1)
    processed_images.append(cv2.cvtColor(sharpened1, cv2.COLOR_GRAY2BGR))
    
    kernel2 = np.array([[0,-1,0], [-1,5,-1], [0,-1,0]])
    sharpened2 = cv2.filter2D(gray, -1, kernel2)
    processed_images.append(cv2.cvtColor(sharpened2, cv2.COLOR_GRAY2BGR))
    
    # 5. Morphological operations
    kernel = np.ones((3,3), np.uint8)
    opened = cv2.morphologyEx(gray, cv2.MORPH_OPEN, kernel)
    processed_images.append(cv2.cvtColor(opened, cv2.COLOR_GRAY2BGR))
    
    closed = cv2.morphologyEx(gray, cv2.MORPH_CLOSE, kernel)
    processed_images.append(cv2.cvtColor(closed, cv2.COLOR_GRAY2BGR))
    
    # 6. Edge detection
    edges = cv2.Canny(gray, 50, 150)
    processed_images.append(cv2.cvtColor(edges, cv2.COLOR_GRAY2BGR))
    
    # 7. PIL-based enhancements
    enhancer = ImageEnhance.Contrast(pil_image)
    contrasted = enhancer.enhance(2.0)
    processed_images.append(cv2.cvtColor(np.array(contrasted), cv2.COLOR_RGB2BGR))
    
    enhancer = ImageEnhance.Sharpness(pil_image)
    sharpened_pil = enhancer.enhance(2.0)
    processed_images.append(cv2.cvtColor(np.array(sharpened_pil), cv2.COLOR_RGB2BGR))
    
    # 8. Different scaling
    height, width = image.shape[:2]
    scaled_up = cv2.resize(image, (width*2, height*2), interpolation=cv2.INTER_CUBIC)
    processed_images.append(scaled_up)
    
    return processed_images

def extract_text_with_all_engines(image):
    """Barcha OCR engine'lardan foydalanish"""
    all_texts = []
    
    # EasyOCR with different parameters
    try:
        results = reader.readtext(image, detail=1, paragraph=True)
        easyocr_text = []
        for (bbox, text, confidence) in results:
            if confidence > 0.2:  # Lower threshold for better recall
                easyocr_text.append(text)
        all_texts.extend(easyocr_text)
    except Exception as e:
        print(f"EasyOCR error: {e}")
    
    # Tesseract with extensive configs
    tesseract_configs = [
        '--oem 3 --psm 6 -l rus+eng',
        '--oem 3 --psm 7 -l rus+eng',
        '--oem 3 --psm 8 -l rus+eng',
        '--oem 3 --psm 9 -l rus+eng',
        '--oem 3 --psm 10 -l rus+eng',
        '--oem 3 --psm 11 -l rus+eng',
        '--oem 3 --psm 12 -l rus+eng',
        '--oem 3 --psm 13 -l rus+eng',
        '--oem 1 --psm 6 -l rus+eng',
        '--oem 1 --psm 8 -l rus+eng',
    ]
    
    for config in tesseract_configs:
        try:
            text = pytesseract.image_to_string(image, config=config)
            if text.strip():
                all_texts.append(text)
        except Exception as e:
            print(f"Tesseract error with config {config}: {e}")
    
    return '\n'.join(all_texts)

def enhanced_blip_analysis(image):
    """Kuchaytirgan BLIP tahlili"""
    try:
        pil_image = Image.fromarray(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
        
        # General captioning
        inputs = blip_processor(pil_image, return_tensors="pt")
        out = blip_model.generate(**inputs, max_length=100)
        caption = blip_processor.decode(out[0], skip_special_tokens=True)
        
        # Kolodets-specific questions
        specific_questions = [
            "What construction materials are visible in this technical drawing?",
            "What pipes or tubes can you see in this scheme?",
            "Are there any concrete rings or cylinders?",
            "What metal objects or fittings are present?",
            "Is this a water well or sewage system diagram?",
            "What circular or cylindrical objects are shown?",
            "Are there any valves or connection points?",
            "What measurements or dimensions are visible?",
            "Are there any covers or lids shown?",
            "What type of construction scheme is this?"
        ]
        
        answers = []
        for question in specific_questions:
            try:
                inputs = blip_processor(pil_image, question, return_tensors="pt")
                out = blip_model.generate(**inputs, max_length=80)
                answer = blip_processor.decode(out[0], skip_special_tokens=True)
                answers.append(answer)
            except Exception as e:
                print(f"BLIP QA error for question '{question}': {e}")
                answers.append("")
        
        return {
            'caption': caption,
            'qa_results': answers,
            'questions': specific_questions
        }
    except Exception as e:
        print(f"BLIP analysis error: {e}")
        return {'caption': '', 'qa_results': [], 'questions': []}

def clip_based_classification(image):
    """CLIP model bilan klassifikatsiya"""
    try:
        pil_image = Image.fromarray(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
        
        # Kolodets-specific class labels
        class_labels = [
            "concrete ring", "concrete cylinder", "water well", "sewage system",
            "pipe", "tube", "fitting", "valve", "manhole cover", "bottom plate",
            "technical drawing", "construction scheme", "plumbing diagram",
            "water supply system", "drainage system"
        ]
        
        inputs = clip_processor(text=class_labels, images=pil_image, return_tensors="pt", padding=True)
        outputs = clip_model(**inputs)
        logits_per_image = outputs.logits_per_image
        probs = logits_per_image.softmax(dim=1)
        
        # Get top 5 classifications
        top_probs, top_indices = torch.topk(probs, 5)
        
        classifications = []
        for i in range(5):
            classifications.append({
                'label': class_labels[top_indices[0][i]],
                'confidence': float(top_probs[0][i])
            })
        
        return classifications
    except Exception as e:
        print(f"CLIP classification error: {e}")
        return []

def advanced_yolo_detection(image):
    """Kuchaytirgan YOLO detection"""
    try:
        # Multiple confidence thresholds
        thresholds = [0.25, 0.35, 0.45, 0.55]
        all_objects = []
        
        for thresh in thresholds:
            results = yolo_model(image, conf=thresh)
            
            for result in results:
                boxes = result.boxes
                if boxes is not None:
                    for box in boxes:
                        class_id = int(box.cls[0])
                        confidence = float(box.conf[0])
                        class_name = yolo_model.names[class_id]
                        bbox = box.xyxy[0].tolist()
                        
                        # Map YOLO classes to construction materials
                        material_mapping = {
                            'bottle': 'Труба ПНД',
                            'cup': 'Муфта соединительная',
                            'bowl': 'Заглушка',
                            'cell phone': 'Люк',
                            'laptop': 'Схема',
                            'book': 'Техническая документация',
                            'scissors': 'Инструмент',
                            'spoon': 'Фитинг',
                            'knife': 'Уплотнитель'
                        }
                        
                        if class_name in material_mapping:
                            all_objects.append({
                                'class': class_name,
                                'material': material_mapping[class_name],
                                'confidence': confidence,
                                'bbox': bbox,
                                'threshold': thresh
                            })
        
        # Remove duplicates based on bbox overlap
        unique_objects = []
        for obj in all_objects:
            is_duplicate = False
            for existing in unique_objects:
                if calculate_iou(obj['bbox'], existing['bbox']) > 0.5:
                    if obj['confidence'] > existing['confidence']:
                        unique_objects.remove(existing)
                    else:
                        is_duplicate = True
                    break
            if not is_duplicate:
                unique_objects.append(obj)
        
        return unique_objects
    except Exception as e:
        print(f"YOLO detection error: {e}")
        return []

def calculate_iou(box1, box2):
    """Intersection over Union hisoblash"""
    x1_min, y1_min, x1_max, y1_max = box1
    x2_min, y2_min, x2_max, y2_max = box2
    
    # Intersection area
    inter_x_min = max(x1_min, x2_min)
    inter_y_min = max(y1_min, y2_min)
    inter_x_max = min(x1_max, x2_max)
    inter_y_max = min(y1_max, y2_max)
    
    if inter_x_max <= inter_x_min or inter_y_max <= inter_y_min:
        return 0.0
    
    inter_area = (inter_x_max - inter_x_min) * (inter_y_max - inter_y_min)
    
    # Union area
    area1 = (x1_max - x1_min) * (y1_max - y1_min)
    area2 = (x2_max - x2_min) * (y2_max - y2_min)
    union_area = area1 + area2 - inter_area
    
    return inter_area / union_area if union_area > 0 else 0.0

def intelligent_material_extraction(combined_text, blip_results, clip_results, yolo_objects):
    """Aqlli material extraction"""
    materials = []
    
    # Check if it's a kolodets scheme
    is_kolodets = any(keyword in combined_text.lower() for keyword in KOLODETS_SCHEME_KEYWORDS)
    if not is_kolodets:
        # Check BLIP results
        blip_text = ' '.join([blip_results.get('caption', '')] + blip_results.get('qa_results', []))
        is_kolodets = any(keyword in blip_text.lower() for keyword in KOLODETS_SCHEME_KEYWORDS)
    
    if not is_kolodets:
        # Check CLIP results
        kolodets_labels = ['water well', 'sewage system', 'plumbing diagram', 'water supply system', 'drainage system']
        is_kolodets = any(result['label'] in kolodets_labels and result['confidence'] > 0.3 for result in clip_results)
    
    # Use specialized patterns if it's a kolodets scheme
    pattern_source = KOLODETS_MATERIALS if is_kolodets else CONSTRUCTION_MATERIALS
    
    # Text-based extraction
    text_materials = extract_materials_from_enhanced_text(combined_text, pattern_source)
    materials.extend(text_materials)
    
    # BLIP results analysis
    blip_text = blip_results.get('caption', '') + ' ' + ' '.join(blip_results.get('qa_results', []))
    blip_materials = extract_materials_from_enhanced_text(blip_text, pattern_source)
    materials.extend(blip_materials)
    
    # YOLO to materials mapping
    for obj in yolo_objects:
        if 'material' in obj:
            materials.append({
                'name': obj['material'],
                'size': 'Определить по схеме',
                'quantity': 1,
                'category': 'detected_object',
                'unit': 'дона',
                'confidence': obj['confidence'],
                'source': 'yolo'
            })
    
    # Context-based enhancement
    materials = enhance_materials_with_context(materials, combined_text, is_kolodets)
    
    # Remove duplicates and improve accuracy
    unique_materials = remove_duplicates_and_improve(materials)
    
    return unique_materials, is_kolodets

def extract_materials_from_enhanced_text(text, pattern_source):
    """Kuchaytirgan text parsing"""
    materials = []
    lines = text.split('\n')
    
    for line in lines:
        line = line.strip()
        if len(line) < 2:
            continue
            
        line_lower = line.lower()
        
        for category, data in pattern_source.items():
            # Pattern matching with improved accuracy
            for pattern in data['patterns']:
                matches = re.finditer(pattern, line_lower, re.IGNORECASE)
                for match in matches:
                    material_name = match.group(0).title()
                    size = ""
                    quantity = 1
                    
                    # Enhanced size extraction
                    if match.groups():
                        size_parts = [g for g in match.groups() if g and g.isdigit()]
                        if len(size_parts) == 1:
                            size = f"Ø{size_parts[0]}мм"
                        elif len(size_parts) == 2:
                            size = f"{size_parts[0]}-{size_parts[1]}"
                    
                    # Enhanced quantity extraction
                    qty_patterns = [
                        r'(\d+)\s*(?:шт|штук|дона|pc|pieces|комплект)',
                        r'количество\s*[:-]?\s*(\d+)',
                        r'qty\s*[:-]?\s*(\d+)',
                        r'к[-]во\s*[:-]?\s*(\d+)',
                        r'(\d+)\s*' + re.escape(material_name.lower())
                    ]
                    
                    for qty_pattern in qty_patterns:
                        qty_match = re.search(qty_pattern, line_lower)
                        if qty_match:
                            quantity = int(qty_match.group(1))
                            break
                    
                    # Determine unit
                    unit = data.get('unit', 'дона')
                    
                    materials.append({
                        'name': material_name,
                        'size': size or 'Стандарт',
                        'quantity': quantity,
                        'category': category,
                        'unit': unit,
                        'confidence': 0.9,
                        'source': 'text_pattern'
                    })
            
            # Enhanced keyword matching
            for keyword in data['keywords']:
                if keyword in line_lower:
                    # Context-aware size detection
                    size_patterns = [
                        r'(?:' + re.escape(keyword) + r').*?(\d+)(?:[-.](\d+))?(?:\s*мм)?',
                        r'(\d+)(?:[-.](\d+))?\s*.*?' + re.escape(keyword),
                        r'ø\s*(\d+).*?' + re.escape(keyword),
                        r'd\s*(\d+).*?' + re.escape(keyword)
                    ]
                    
                    size = "Стандарт"
                    for size_pattern in size_patterns:
                        size_match = re.search(size_pattern, line_lower)
                        if size_match:
                            if size_match.group(2):
                                size = f"{size_match.group(1)}-{size_match.group(2)}"
                            else:
                                size = f"Ø{size_match.group(1)}мм"
                            break
                    
                    materials.append({
                        'name': keyword.title(),
                        'size': size,
                        'quantity': 1,
                        'category': category,
                        'unit': data.get('unit', 'дона'),
                        'confidence': 0.7,
                        'source': 'text_keyword'
                    })
    
    return materials

def enhance_materials_with_context(materials, text, is_kolodets):
    """Kontekst asosida materiallarni yaxshilash"""
    enhanced_materials = []
    
    for material in materials:
        # Enhanced material based on context
        enhanced_material = material.copy()
        
        # If it's a kolodets scheme, adjust materials accordingly
        if is_kolodets:
            # Standard kolodets materials
            kolodets_standards = {
                'кольцо': {'standard_sizes': ['10-9', '15-9', '20-9'], 'typical_qty': 5},
                'крышка': {'standard_sizes': ['10', '15', '20'], 'typical_qty': 1},
                'плита': {'standard_sizes': ['10', '15', '20'], 'typical_qty': 1},
                'труба': {'standard_sizes': ['110', '160', '200'], 'typical_qty': 10},
                'люк': {'standard_sizes': ['600', '700'], 'typical_qty': 1}
            }
            
            for key, standards in kolodets_standards.items():
                if key in material['name'].lower():
                    if enhanced_material['size'] == 'Стандарт':
                        enhanced_material['size'] = standards['standard_sizes'][0]
                    if enhanced_material['quantity'] == 1 and standards['typical_qty'] > 1:
                        enhanced_material['quantity'] = standards['typical_qty']
                    enhanced_material['confidence'] = min(enhanced_material['confidence'] + 0.1, 1.0)
        
        # Add notes based on context
        notes = []
        if 'водопровод' in text.lower() or 'water' in text.lower():
            notes.append('Для водопроводной системы')
        if 'канализация' in text.lower() or 'sewage' in text.lower():
            notes.append('Для канализационной системы')
        if 'дренаж' in text.lower() or 'drainage' in text.lower():
            notes.append('Для дренажной системы')
        
        enhanced_material['notes'] = notes
        enhanced_materials.append(enhanced_material)
    
    return enhanced_materials

def remove_duplicates_and_improve(materials):
    """Dublikatlarni o'chirish va yaxshilash"""
    # Group similar materials
    grouped = defaultdict(list)
    for material in materials:
        key = f"{material['name'].lower()}_{material['size']}"
        grouped[key].append(material)
    
    unique_materials = []
    for materials_group in grouped.values():
        if len(materials_group) == 1:
            unique_materials.append(materials_group[0])
        else:
            # Merge similar materials
            best_material = max(materials_group, key=lambda x: x['confidence'])
            total_quantity = sum(m['quantity'] for m in materials_group)
            
            best_material['quantity'] = total_quantity
            best_material['confidence'] = min(best_material['confidence'] + 0.1, 1.0)
            best_material['sources'] = list(set(m.get('source', 'unknown') for m in materials_group))
            
            unique_materials.append(best_material)
    
    # Sort by confidence and relevance
    unique_materials.sort(key=lambda x: (x['confidence'], x['quantity']), reverse=True)
    
    return unique_materials

@app.route('/detect_materials', methods=['POST'])
def detect_materials():
    try:
        print("Запуск ультра-продвинутого определения материалов...")
        
        # Получение изображения
        image = None
        
        # Проверяем тип контента
        content_type = request.content_type or ''
        print(f"Content-Type: {content_type}")
        
        if 'multipart/form-data' in content_type and 'file' in request.files:
            print("Обработка multipart/form-data файла...")
            file = request.files['file']
            if file.filename == '':
                return jsonify({'success': False, 'error': 'Файл не выбран'}), 400
            image_bytes = file.read()
            image = cv2.imdecode(np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR)
            
        elif request.is_json:
            print("Обработка JSON запроса...")
            if 'image_url' in request.json:
                image_url = request.json['image_url']
                response = requests.get(image_url)
                image = Image.open(BytesIO(response.content))
                image = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
            elif 'image_base64' in request.json:
                image_data = base64.b64decode(request.json['image_base64'])
                image = cv2.imdecode(np.frombuffer(image_data, np.uint8), cv2.IMREAD_COLOR)
        else:
            return jsonify({'success': False, 'error': 'Неподдерживаемый тип контента'}), 400

        if image is None:
            return jsonify({'success': False, 'error': 'Не удалось загрузить изображение'}), 400
        
        print("Изображение успешно загружено")
        
        # Ультра-продвинутая предобработка
        processed_images = ultra_advanced_preprocessing(image)
        print(f"Создано {len(processed_images)} обработанных версий")
        
        # Извлечение текста из всех обработанных изображений
        all_texts = []
        for i, proc_img in enumerate(processed_images):
            print(f"Обработка варианта изображения {i+1}/{len(processed_images)}")
            text = extract_text_with_all_engines(proc_img)
            if text.strip():
                all_texts.append(text)
        
        combined_text = '\n'.join(all_texts)
        print(f"Извлечение текста завершено. Длина: {len(combined_text)}")
        
        # Улучшенный анализ BLIP
        print("Запуск улучшенного анализа BLIP...")
        blip_results = enhanced_blip_analysis(image)
        
        # Классификация на основе CLIP
        print("Запуск классификации CLIP...")
        clip_results = clip_based_classification(image)
        
        # Продвинутое обнаружение YOLO
        print("Запуск продвинутого обнаружения YOLO...")
        yolo_objects = advanced_yolo_detection(image)
        
        # Интеллектуальное извлечение материалов
        print("Запуск интеллектуального извлечения материалов...")
        materials, is_kolodets_scheme = intelligent_material_extraction(
            combined_text, blip_results, clip_results, yolo_objects
        )
        
        # Расчет общей уверенности
        overall_confidence = calculate_overall_confidence(materials, combined_text, blip_results, clip_results)
        
        # Генерация рекомендаций
        recommendations = generate_recommendations(materials, is_kolodets_scheme, overall_confidence)
        
        print(f"Обнаружение завершено! Найдено {len(materials)} материалов с уверенностью {overall_confidence:.1%}")
        
        return jsonify({
            'success': True,
            'materials': materials,
            'is_kolodets_scheme': is_kolodets_scheme,
            'overall_confidence': overall_confidence,
            'recommendations': recommendations,
            'analysis_results': {
                'detected_text': combined_text,
                'blip_analysis': blip_results,
                'clip_classification': clip_results,
                'yolo_objects': yolo_objects,
                'total_materials': len(materials),
                'processing_info': {
                    'processed_images': len(processed_images),
                    'text_length': len(combined_text),
                    'blip_caption': blip_results.get('caption', ''),
                    'clip_top_class': clip_results[0]['label'] if clip_results else 'unknown',
                    'yolo_detections': len(yolo_objects)
                }
            }
        })
        
    except Exception as e:
        print(f"Ошибка в определении материалов: {e}")
        return jsonify({
            'success': False,
            'error': str(e),
            'error_type': type(e).__name__
        }), 500

def calculate_overall_confidence(materials, text, blip_results, clip_results):
    """Umumiy ishonchlilik darajasini hisoblash"""
    if not materials:
        return 0.0
    
    # Material confidence average
    material_confidence = sum(m['confidence'] for m in materials) / len(materials)
    
    # Text quality score
    text_quality = min(len(text) / 1000, 1.0)  # Longer text = better quality
    
    # BLIP confidence (based on caption length and content quality)
    blip_confidence = 0.5
    if blip_results.get('caption'):
        blip_confidence = min(len(blip_results['caption']) / 100, 1.0)
    
    # CLIP confidence (top classification score)
    clip_confidence = 0.5
    if clip_results:
        clip_confidence = clip_results[0]['confidence']
    
    # Weighted average
    overall = (
        material_confidence * 0.4 +
        text_quality * 0.2 +
        blip_confidence * 0.2 +
        clip_confidence * 0.2
    )
    
    return overall

def generate_recommendations(materials, is_kolodets, confidence):
    """Tavsiyalar generatsiya qilish"""
    recommendations = []
    
    if confidence < 0.7:
        recommendations.append({
            'type': 'warning',
            'message': 'Анализ показал низкую точность. Рекомендуется проверить результаты вручную.',
            'suggestion': 'Попробуйте загрузить более четкое изображение схемы.'
        })
    
    if is_kolodets:
        recommendations.append({
            'type': 'info',
            'message': 'Обнаружена схема колодца водоснабжения/канализации.',
            'suggestion': 'Проверьте соответствие материалов нормативам СНиП.'
        })
        
        # Check for essential kolodets materials
        essential_materials = ['кольцо', 'крышка', 'люк', 'труба']
        found_essential = [mat for mat in materials if any(ess in mat['name'].lower() for ess in essential_materials)]
        
        if len(found_essential) < 3:
            recommendations.append({
                'type': 'warning',
                'message': 'Не все основные элементы колодца обнаружены.',
                'suggestion': 'Убедитесь, что на схеме присутствуют: кольца, крышка, люк, трубы.'
            })
    
    # Material-specific recommendations
    high_quantity_materials = [m for m in materials if m['quantity'] > 10]
    if high_quantity_materials:
        recommendations.append({
            'type': 'info',
            'message': f'Обнаружены материалы в больших количествах: {", ".join([m["name"] for m in high_quantity_materials])}',
            'suggestion': 'Проверьте правильность подсчета количества материалов.'
        })
    
    return recommendations

@app.route('/analyze_kolodets_scheme', methods=['POST'])
def analyze_kolodets_scheme():
    """Специализированный анализ схем колодцев"""
    try:
        # Call the main detection function
        detection_result = detect_materials()
        
        if isinstance(detection_result, tuple):
            response_data, status_code = detection_result
            if status_code != 200:
                return detection_result
            response_data = response_data.get_json()
        else:
            response_data = detection_result.get_json()
        
        if not response_data.get('success'):
            return jsonify(response_data), 400
        
        materials = response_data['materials']
        is_kolodets = response_data['is_kolodets_scheme']
        
        # Enhanced kolodets-specific analysis
        kolodets_analysis = {
            'scheme_type': 'unknown',
            'depth_estimate': 'не определена',
            'diameter_estimate': 'не определен',
            'material_completeness': 0.0,
            'construction_feasibility': 'unknown',
            'estimated_cost': 'не рассчитана'
        }
        
        if is_kolodets:
            # Determine scheme type
            if any('канализация' in str(m).lower() for m in materials):
                kolodets_analysis['scheme_type'] = 'канализационный колодец'
            elif any('водопровод' in str(m).lower() for m in materials):
                kolodets_analysis['scheme_type'] = 'водопроводный колодец'
            elif any('дренаж' in str(m).lower() for m in materials):
                kolodets_analysis['scheme_type'] = 'дренажный колодец'
            else:
                kolodets_analysis['scheme_type'] = 'универсальный колодец'
            
            # Estimate dimensions from materials
            rings = [m for m in materials if 'кольцо' in m['name'].lower()]
            if rings:
                ring_sizes = [m['size'] for m in rings if m['size'] != 'Стандарт']
                if ring_sizes:
                    # Parse ring size (e.g., "10-9" means diameter 10, height 9)
                    for size in ring_sizes:
                        if '-' in size:
                            diameter, height = size.split('-')
                            kolodets_analysis['diameter_estimate'] = f"{diameter}0 см"
                            total_rings = sum(m['quantity'] for m in rings)
                            kolodets_analysis['depth_estimate'] = f"{int(height) * total_rings} см"
                            break
            
            # Check material completeness
            essential_categories = ['concrete_rings', 'concrete_covers', 'bottom_plates', 'pipes', 'manholes']
            found_categories = set(m['category'] for m in materials)
            completeness = len(found_categories.intersection(essential_categories)) / len(essential_categories)
            kolodets_analysis['material_completeness'] = completeness
            
            # Construction feasibility
            if completeness > 0.8:
                kolodets_analysis['construction_feasibility'] = 'высокая'
            elif completeness > 0.6:
                kolodets_analysis['construction_feasibility'] = 'средняя'
            else:
                kolodets_analysis['construction_feasibility'] = 'низкая'
        
        # Add kolodets analysis to response
        response_data['kolodets_analysis'] = kolodets_analysis
        
        return jsonify(response_data)
        
    except Exception as e:
        print(f"Error in kolodets scheme analysis: {e}")
        return jsonify({
            'success': False,
            'error': str(e),
            'error_type': type(e).__name__
        }), 500

@app.route('/get_material_specifications', methods=['POST'])
def get_material_specifications():
    """Материалlar спецификацияси"""
    try:
        materials = request.json.get('materials', [])
        
        specifications = []
        for material in materials:
            spec = {
                'name': material['name'],
                'size': material['size'],
                'quantity': material['quantity'],
                'unit': material['unit'],
                'technical_specs': get_technical_specifications(material),
                'suppliers': get_potential_suppliers(material),
                'price_range': get_price_range(material),
                'installation_notes': get_installation_notes(material)
            }
            specifications.append(spec)
        
        return jsonify({
            'success': True,
            'specifications': specifications,
            'total_items': len(specifications)
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

def get_technical_specifications(material):
    """Texnik spetsifikatsiyalar"""
    specs = {
        'standard': 'ГОСТ/СНиП',
        'material_type': 'определить',
        'strength_class': 'определить',
        'temperature_range': 'определить',
        'pressure_rating': 'определить'
    }
    
    name_lower = material['name'].lower()
    
    if 'кольцо' in name_lower:
        specs.update({
            'standard': 'ГОСТ 8020-90',
            'material_type': 'железобетон',
            'strength_class': 'B15-B25',
            'temperature_range': '-40°C до +50°C',
            'pressure_rating': 'до 0.1 МПа'
        })
    elif 'труба' in name_lower:
        specs.update({
            'standard': 'ГОСТ 18599-2001',
            'material_type': 'полиэтилен низкого давления',
            'strength_class': 'SDR 17',
            'temperature_range': '-20°C до +40°C',
            'pressure_rating': '1.0 МПа'
        })
    elif 'люк' in name_lower:
        specs.update({
            'standard': 'ГОСТ 3634-99',
            'material_type': 'чугун',
            'strength_class': 'класс A15',
            'temperature_range': '-40°C до +70°C',
            'pressure_rating': 'нагрузка 1.5 т'
        })
    
    return specs

def get_potential_suppliers(material):
    """Potensial ta'minotchilar"""
    suppliers = [
        'Местные строительные базы',
        'Региональные дистрибьюторы',
        'Производители железобетонных изделий',
        'Специализированные поставщики'
    ]
    
    return suppliers

def get_price_range(material):
    """Narx diapazoni"""
    # This would typically connect to a pricing database
    return {
        'min_price': 'уточнить',
        'max_price': 'уточнить',
        'currency': 'сум',
        'unit': material['unit'],
        'last_updated': 'требует актуализации'
    }

def get_installation_notes(material):
    """O'rnatish eslatmalari"""
    notes = []
    
    name_lower = material['name'].lower()
    
    if 'кольцо' in name_lower:
        notes.extend([
            'Установка с использованием крана',
            'Проверка герметичности стыков',
            'Обязательная гидроизоляция'
        ])
    elif 'труба' in name_lower:
        notes.extend([
            'Соблюдение уклонов',
            'Проверка на герметичность',
            'Использование специальных фитингов'
        ])
    elif 'люк' in name_lower:
        notes.extend([
            'Установка на уровне покрытия',
            'Обеспечение доступа для обслуживания',
            'Проверка несущей способности'
        ])
    
    return notes

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy', 
        'message': 'Ultra-Advanced AI Material Detection API is running',
        'version': '2.0.0',
        'models_loaded': {
            'easyocr': True,
            'tesseract': True,
            'blip': True,
            'clip': True,
            'yolo': True
        },
        'specialized_features': {
            'kolodets_detection': True,
            'material_specifications': True,
            'confidence_scoring': True,
            'recommendations': True
        }
    })

@app.route('/supported_materials', methods=['GET'])
def supported_materials():
    """Qo'llab-quvvatlanadigan materiallar ro'yxati"""
    return jsonify({
        'success': True,
        'kolodets_materials': list(KOLODETS_MATERIALS.keys()),
        'general_materials': list(CONSTRUCTION_MATERIALS.keys()),
        'detection_keywords': KOLODETS_SCHEME_KEYWORDS,
        'total_patterns': sum(len(data['patterns']) for data in KOLODETS_MATERIALS.values())
    })

if __name__ == '__main__':
    print("🚀 Ultra-Advanced AI Material Detection API starting...")
    print("🎯 Specialized for Kolodets (Well) Construction Schemes")
    print("🧠 Enhanced with CLIP, Advanced YOLO, and Intelligent Processing")
    
    # Windows uchun maxsus sozlamalar
    import sys
    if sys.platform == "win32":
        import os
        os.system('title Python AI Material Detection API')
    
    try:
        app.run(host='127.0.0.1', port=5001, debug=False, threaded=True)
    except Exception as e:
        print(f"❌ Server ishga tushirishda xatolik: {e}")
        input("Press Enter to exit...")



