import os
import tempfile
import yt_dlp
from flask import Flask, request, render_template, send_file, redirect, url_for
from io import BytesIO

# 1. إعداد تطبيق Flask
# يجب أن يكون اسم التطبيق 'app' لكي يتعرف عليه Gunicorn في Dockerfile.
app = Flask(__name__)

# 2. المسار الرئيسي (عرض صفحة index.html)
@app.route('/', methods=['GET'])
def index():
    """عرض الصفحة الرئيسية التي تحتوي على حقل إدخال الرابط."""
    # يبحث Flask عن index.html داخل مجلد 'templates'
    return render_template('index.html')

# 3. مسار معالجة التنزيل
@app.route('/download', methods=['POST'])
def download_video():
    """يستقبل رابط الفيديو ويقوم بتنزيله وإرساله للمستخدم."""
    video_url = request.form.get('url')
    
    if not video_url:
        return "<h1>خطأ: الرجاء إدخال رابط فيديو صالح.</h1>", 400

    # Hugging Face Spaces تسمح بالكتابة فقط في مجلد /tmp
    # لذلك نستخدم tempfile لإنشاء ملف مؤقت آمن
    try:
        # إنشاء ملف مؤقت في مجلد /tmp بمسار كامل
        temp_dir = tempfile.gettempdir()
        file_path = os.path.join(temp_dir, 'downloaded_video.mp4')
        
        # إعداد خيارات yt-dlp
        ydl_opts = {
            # تحديد مسار التخزين المؤقت
            'outtmpl': file_path,
            # اختيار أفضل جودة فيديو (مع الصوت)
            'format': 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best',
            # عدم طباعة رسائل كثيرة في السجلات
            'quiet': True,
        }

        # تشغيل yt-dlp لتنزيل الفيديو
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info_dict = ydl.extract_info(video_url, download=True)
            # استخراج اسم الملف للحصول على اسم لائق للتنزيل
            final_filename = ydl.prepare_filename(info_dict)

        # 4. إرسال الملف إلى المستخدم
        # نستخدم send_file لإرسال الملف المؤقت مباشرة للمتصفح
        # as_attachment=True تعني أن المتصفح سيقوم بتنزيل الملف بدلاً من عرضه
        response = send_file(
            path_or_file=file_path, 
            as_attachment=True, 
            download_name=os.path.basename(final_filename),
            mimetype='video/mp4' # نوع الملف
        )
        return response

    except Exception as e:
        # إذا حدث أي خطأ (مثل الرابط غير صحيح أو قيود في yt-dlp)
        print(f"حدث خطأ أثناء التنزيل: {e}")
        return f"<h1>عذراً، حدث خطأ أثناء معالجة الرابط.</h1><p>الخطأ: {e}</p>", 500
    
    finally:
        # 5. تنظيف (Clean up)
        # التأكد من حذف الملف المؤقت بعد الانتهاء، سواء نجح التنزيل أو فشل.
        if os.path.exists(file_path):
            os.remove(file_path)

# 6. تشغيل التطبيق (لا يتم استخدامه في Docker، ولكن نتركه للاختبار المحلي)
if __name__ == '__main__':
    # في بيئة الإنتاج (Hugging Face) يتم استخدام Gunicorn بدلاً من هذا
    app.run(debug=True, host='0.0.0.0', port=7860)
