# LEGENDS OF FIGHT – افسانه‌های مبارزه

بازی مبارزه‌ای سه‌بعدی اندروید (Godot 4.3 / GDScript) با الهام از سبک Tekken.
3D fighting game for Android, built with Godot 4.3 and GDScript. All art is procedural (no copyrighted assets).

## امکانات / Features
- 12 مبارز با آمار و سبک متفاوت (۶ مبارز اول باز هستند، بقیه با پیروزی آزاد می‌شوند)
- 8 محیط سه‌بعدی با نورپردازی، سایه، باران/برف/جرقه و موسیقی اختصاصی
- حالت‌ها: Single Player (آسان/متوسط/سخت)، Two Player Local، Tournament (۱۰ مرحله + باس)، Practice
- ضربات سریع و سنگین، کمبوی سه‌ضربه‌ای، دفاع، جاخالی، حرکت ویژه و Ultimate، Hitbox/Hurtbox
- کنترل لمسی چندلمسی؛ در حالت دونفره کنترل جدا برای هر بازیکن
- هوش مصنوعی با فاصله‌سنجی، دفاع، جاخالی، کمبو و سختی پلکانی
- فارسی (پیش‌فرض) و انگلیسی، کیفیت گرافیک Low/Medium/High، ذخیره پیشرفت، کاملاً آفلاین

## اجرا / Run
1. Godot 4.3 را باز کنید و پوشه پروژه را Import کنید، سپس F5.
2. کنترل کیبورد برای تست: A/D/W حرکت، F مشت، G لگد، H دفاع، T ویژه؛ بازیکن دوم: ← → ↑ و J K L I.

## ساخت APK / Build APK
```
git init && git add . && git commit -m "Legends of Fight"
git branch -M main
git remote add origin https://github.com/<USER>/legends-of-fight-android.git
git push -u origin main
```
- با هر push روی main یا اجرای دستی (Actions → Build Android APK → Run workflow) APK ساخته و به‌عنوان Artifact ذخیره می‌شود.
- برای انتشار در Releases: `git tag v1.0.0 && git push origin v1.0.0`
- خروجی: `LegendsOfFight.apk` (Release) و `LegendsOfFight-debug.apk`

برای نمایش بهتر متن فارسی می‌توانید فونت Vazirmatn را با نام `assets/fonts/Vazirmatn.ttf` اضافه کنید (خودکار استفاده می‌شود).
