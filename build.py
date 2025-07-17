import os
import sys
import subprocess
import shutil
import json
import zipfile
import urllib.request
from pathlib import Path
import time

class FlutterSetupAndBuilder:
    def __init__(self, project_path=None):
        self.project_path = project_path or os.getcwd()
        self.flutter_dir = os.path.join(os.path.expanduser("~"), "flutter")
        self.flutter_bin = os.path.join(self.flutter_dir, "bin", "flutter.exe")
        self.build_dir = os.path.join(self.project_path, "build", "windows", "runner", "Release")
        self.installer_dir = os.path.join(self.project_path, "installer")
        self.app_name = self.get_app_name()
        
    def print_step(self, message):
        """Step messageni chiroyli formatda chiqarish"""
        print(f"\n{'='*60}")
        print(f"🚀 {message}")
        print(f"{'='*60}")
        
    def print_success(self, message):
        """Success messageni chiroyli formatda chiqarish"""
        print(f"\n✅ {message}")
        
    def print_error(self, message):
        """Error messageni chiroyli formatda chiqarish"""
        print(f"\n❌ {message}")
        
    def print_info(self, message):
        """Info messageni chiroyli formatda chiqarish"""
        print(f"\n💡 {message}")
        
    def get_app_name(self):
        """pubspec.yaml dan app nomini olish"""
        try:
            pubspec_path = os.path.join(self.project_path, "pubspec.yaml")
            with open(pubspec_path, 'r', encoding='utf-8') as f:
                for line in f:
                    if line.strip().startswith('name:'):
                        return line.split(':')[1].strip()
        except Exception as e:
            self.print_error(f"pubspec.yaml o'qishda xatolik: {e}")
            return "MyApp"
        return "MyApp"
    
    def check_flutter_installation(self):
        """Flutter o'rnatilganligini tekshirish"""
        self.print_step("Flutter o'rnatilganligini tekshirish...")
        
        # Global PATH dan tekshirish
        try:
            result = subprocess.run(['flutter', '--version'], 
                                  capture_output=True, text=True, shell=True)
            if result.returncode == 0:
                self.print_success("Flutter global PATH da topildi!")
                print(f"   Flutter versiyasi: {result.stdout.split()[1] if result.stdout else 'Unknown'}")
                return True
        except Exception as e:
            self.print_error(f"Flutter PATH tekshirishda xatolik: {e}")
        
        # flutter.bat dan tekshirish
        try:
            result = subprocess.run(['flutter.bat', '--version'], 
                                  capture_output=True, text=True, shell=True)
            if result.returncode == 0:
                self.print_success("Flutter (.bat) PATH da topildi!")
                print(f"   Flutter versiyasi: {result.stdout.split()[1] if result.stdout else 'Unknown'}")
                return True
        except Exception as e:
            self.print_error(f"Flutter.bat tekshirishda xatolik: {e}")
        
        # Local flutter papkasidan tekshirish
        if os.path.exists(self.flutter_bin):
            try:
                result = subprocess.run([self.flutter_bin, '--version'], 
                                      capture_output=True, text=True, shell=True)
                if result.returncode == 0:
                    self.print_success("Flutter local papkada topildi!")
                    return True
            except Exception:
                pass
        
        self.print_error("Flutter topilmadi!")
        return False
    
    def download_flutter(self):
        """Flutter SDK ni yuklab olish"""
        self.print_step("Flutter SDK ni yuklab olish...")
        
        flutter_url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip"
        flutter_zip = os.path.join(os.path.expanduser("~"), "flutter.zip")
        
        try:
            self.print_info("Flutter SDK yuklab olinmoqda... (Bu biroz vaqt olishi mumkin)")
            
            # Progressni ko'rsatish uchun
            def progress_hook(block_num, block_size, total_size):
                percent = (block_num * block_size * 100) // total_size
                if percent % 10 == 0:
                    print(f"   Progress: {percent}%")
            
            urllib.request.urlretrieve(flutter_url, flutter_zip, progress_hook)
            self.print_success("Flutter SDK yuklandi!")
            return flutter_zip
            
        except Exception as e:
            self.print_error(f"Flutter SDK yuklab olishda xatolik: {e}")
            return None
    
    def extract_flutter(self, flutter_zip):
        """Flutter SDK ni chiqarish"""
        self.print_step("Flutter SDK ni chiqarish...")
        
        try:
            home_dir = os.path.expanduser("~")
            
            # Eski flutter papkasini o'chirish
            if os.path.exists(self.flutter_dir):
                shutil.rmtree(self.flutter_dir)
            
            # ZIP faylni chiqarish
            with zipfile.ZipFile(flutter_zip, 'r') as zip_ref:
                zip_ref.extractall(home_dir)
            
            # ZIP faylni o'chirish
            os.remove(flutter_zip)
            
            self.print_success(f"Flutter SDK chiqarildi: {self.flutter_dir}")
            return True
            
        except Exception as e:
            self.print_error(f"Flutter SDK chiqarishda xatolik: {e}")
            return False
    
    def add_flutter_to_path(self):
        """Flutter ni PATH ga qo'shish"""
        self.print_step("Flutter ni PATH ga qo'shish...")
        
        try:
            flutter_bin_dir = os.path.join(self.flutter_dir, "bin")
            
            # Windows PATH ga qo'shish
            current_path = os.environ.get('PATH', '')
            if flutter_bin_dir not in current_path:
                # Faqat joriy session uchun
                os.environ['PATH'] = flutter_bin_dir + ';' + current_path
                self.print_success("Flutter PATH ga qo'shildi (joriy session uchun)")
            else:
                self.print_success("Flutter allaqachon PATH da mavjud")
            
            return True
            
        except Exception as e:
            self.print_error(f"Flutter ni PATH ga qo'shishda xatolik: {e}")
            return False
    
    def install_flutter_automatically(self):
        """Flutter ni avtomatik o'rnatish"""
        self.print_step("Flutter ni avtomatik o'rnatish...")
        
        # Flutter yuklab olish
        flutter_zip = self.download_flutter()
        if not flutter_zip:
            return False
        
        # Flutter chiqarish
        if not self.extract_flutter(flutter_zip):
            return False
        
        # PATH ga qo'shish
        if not self.add_flutter_to_path():
            return False
        
        # Flutter doctor ishga tushirish
        return self.run_flutter_doctor()
    
    def run_flutter_doctor(self):
        """Flutter doctor ishga tushirish"""
        self.print_step("Flutter doctor ishga tushirish...")
        
        try:
            flutter_cmd = self.flutter_bin if os.path.exists(self.flutter_bin) else 'flutter'
            
            # Flutter doctor
            result = subprocess.run([flutter_cmd, 'doctor'], 
                                  capture_output=True, text=True)
            
            if result.returncode == 0:
                self.print_success("Flutter doctor muvaffaqiyatli!")
                return True
            else:
                self.print_error(f"Flutter doctor da xatolik: {result.stderr}")
                # Xatolik bo'lsa ham davom etamiz
                return True
                
        except Exception as e:
            self.print_error(f"Flutter doctor ishga tushirishda xatolik: {e}")
            return False
    
    def get_flutter_command(self):
        """Flutter buyrugi yo'lini olish"""
        # Avval global PATH dan tekshirish
        try:
            result = subprocess.run(['flutter', '--version'], 
                                  capture_output=True, text=True, shell=True)
            if result.returncode == 0:
                return 'flutter'
        except:
            pass
        
        # flutter.bat dan tekshirish  
        try:
            result = subprocess.run(['flutter.bat', '--version'], 
                                  capture_output=True, text=True, shell=True)
            if result.returncode == 0:
                return 'flutter.bat'
        except:
            pass
        
        # Local flutter papkasidan tekshirish
        if os.path.exists(self.flutter_bin):
            return self.flutter_bin
        
        return 'flutter'
    
    def check_project_structure(self):
        """Flutter loyihasi strukturasini tekshirish"""
        self.print_step("Flutter loyihasi strukturasini tekshirish...")
        
        required_files = ['pubspec.yaml', 'lib/main.dart']
        
        for file in required_files:
            file_path = os.path.join(self.project_path, file)
            if not os.path.exists(file_path):
                self.print_error(f"Kerakli fayl topilmadi: {file}")
                return False
        
        # Windows papkasini tekshirish
        windows_dir = os.path.join(self.project_path, "windows")
        if not os.path.exists(windows_dir):
            self.print_info("Windows papkasi topilmadi. Windows support yoqiladi...")
        
        self.print_success("Loyiha strukturasi to'g'ri!")
        return True
    
    def enable_windows_support(self):
        """Windows support yoqish"""
        self.print_step("Windows support yoqish...")
        
        flutter_cmd = self.get_flutter_command()
        
        try:
            # Windows desktop yoqish
            result = subprocess.run([flutter_cmd, 'config', '--enable-windows-desktop'], 
                                  cwd=self.project_path, capture_output=True, text=True, shell=True)
            
            if result.returncode == 0:
                self.print_success("Windows desktop yoqildi!")
            else:
                self.print_error(f"Windows desktop yoqishda xatolik: {result.stderr}")
            
            # Windows papkasi mavjudligini tekshirish
            windows_dir = os.path.join(self.project_path, "windows")
            if not os.path.exists(windows_dir):
                # Windows platform yaratish
                result = subprocess.run([flutter_cmd, 'create', '--platforms=windows', '.'], 
                                      cwd=self.project_path, capture_output=True, text=True, shell=True)
                
                if result.returncode == 0:
                    self.print_success("Windows platform yaratildi!")
                else:
                    self.print_error(f"Windows platform yaratishda xatolik: {result.stderr}")
            else:
                self.print_success("Windows platform allaqachon mavjud!")
            
            return True
                
        except Exception as e:
            self.print_error(f"Windows support yoqishda xatolik: {e}")
            return False
    
    def get_dependencies(self):
        """Dependencies olish"""
        self.print_step("Dependencies olish...")
        
        flutter_cmd = self.get_flutter_command()
        
        try:
            result = subprocess.run([flutter_cmd, 'pub', 'get'], 
                                  cwd=self.project_path, capture_output=True, text=True, shell=True)
            if result.returncode == 0:
                self.print_success("Dependencies muvaffaqiyatli olindi!")
                return True
            else:
                self.print_error(f"Dependencies olishda xatolik: {result.stderr}")
                return False
        except Exception as e:
            self.print_error(f"Dependencies olishda xatolik: {e}")
            return False
    
    def build_windows_release(self):
        """Windows release build qilish"""
        self.print_step("Windows release build qilish...")
        
        flutter_cmd = self.get_flutter_command()
        
        try:
            result = subprocess.run([flutter_cmd, 'build', 'windows', '--release'], 
                                  cwd=self.project_path, capture_output=True, text=True, shell=True)
            if result.returncode == 0:
                self.print_success("Windows build muvaffaqiyatli yaratildi!")
                return True
            else:
                self.print_error(f"Build qilishda xatolik: {result.stderr}")
                # Stdout ham ko'rsatish
                if result.stdout:
                    print(f"   Stdout: {result.stdout}")
                return False
        except Exception as e:
            self.print_error(f"Build qilishda xatolik: {e}")
            return False
    
    def create_installer_files(self):
        """Installer uchun kerakli fayllarni yaratish"""
        self.print_step("Installer uchun fayllar yaratish...")
        
        # Installer papkasini yaratish
        os.makedirs(self.installer_dir, exist_ok=True)
        
        # Batch installer yaratish
        batch_script = f'''@echo off
title {self.app_name} Installer
color 0A

echo.
echo ===============================================
echo    {self.app_name} Installer
echo ===============================================
echo.

set "INSTALL_DIR=%PROGRAMFILES%\\{self.app_name}"

echo Installing {self.app_name}...
echo.

if not exist "%INSTALL_DIR%" (
    echo Creating installation directory...
    mkdir "%INSTALL_DIR%"
)

echo Copying application files...
xcopy /E /I /H /Y "..\\build\\windows\\runner\\Release\\*" "%INSTALL_DIR%\\" > nul

if %ERRORLEVEL% EQU 0 (
    echo ✓ Files copied successfully
) else (
    echo ✗ Error copying files
    pause
    exit /b 1
)

echo Creating desktop shortcut...
powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\\Desktop\\{self.app_name}.lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\\{self.app_name}.exe'; $Shortcut.Save()" > nul

if %ERRORLEVEL% EQU 0 (
    echo ✓ Desktop shortcut created
) else (
    echo ✗ Error creating desktop shortcut
)

echo Creating start menu shortcut...
if not exist "%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\{self.app_name}" (
    mkdir "%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\{self.app_name}"
)
powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\{self.app_name}\\{self.app_name}.lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\\{self.app_name}.exe'; $Shortcut.Save()" > nul

if %ERRORLEVEL% EQU 0 (
    echo ✓ Start menu shortcut created
) else (
    echo ✗ Error creating start menu shortcut
)

echo.
echo ===============================================
echo    Installation completed successfully!
echo ===============================================
echo.
echo You can find {self.app_name} on your desktop
echo and in the start menu.
echo.
pause
'''
        
        # Uninstaller yaratish
        uninstaller_script = f'''@echo off
title {self.app_name} Uninstaller
color 0C

echo.
echo ===============================================
echo    {self.app_name} Uninstaller
echo ===============================================
echo.

set "INSTALL_DIR=%PROGRAMFILES%\\{self.app_name}"

echo Uninstalling {self.app_name}...
echo.

if exist "%INSTALL_DIR%" (
    echo Removing application files...
    rmdir /S /Q "%INSTALL_DIR%"
    echo ✓ Application files removed
) else (
    echo Application not found in Program Files
)

echo Removing desktop shortcut...
if exist "%USERPROFILE%\\Desktop\\{self.app_name}.lnk" (
    del "%USERPROFILE%\\Desktop\\{self.app_name}.lnk"
    echo ✓ Desktop shortcut removed
) else (
    echo Desktop shortcut not found
)

echo Removing start menu shortcut...
if exist "%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\{self.app_name}" (
    rmdir /S /Q "%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\{self.app_name}"
    echo ✓ Start menu shortcut removed
) else (
    echo Start menu shortcut not found
)

echo.
echo ===============================================
echo    Uninstallation completed successfully!
echo ===============================================
echo.
pause
'''
        
        try:
            # Installer bat faylini yaratish
            installer_path = os.path.join(self.installer_dir, f"{self.app_name}_installer.bat")
            with open(installer_path, 'w', encoding='utf-8') as f:
                f.write(batch_script)
            
            # Uninstaller bat faylini yaratish
            uninstaller_path = os.path.join(self.installer_dir, f"{self.app_name}_uninstaller.bat")
            with open(uninstaller_path, 'w', encoding='utf-8') as f:
                f.write(uninstaller_script)
            
            # README yaratish
            readme_content = f'''
{self.app_name} - Installation Guide
=====================================

Files in this package:
- {self.app_name}_installer.bat   - Install the application
- {self.app_name}_uninstaller.bat - Remove the application
- {self.app_name}_Portable/       - Portable version (no installation needed)
- {self.app_name}_Windows.zip     - ZIP package for manual installation

Installation Instructions:
1. Run {self.app_name}_installer.bat as Administrator
2. Follow the installation process
3. Find the app on your desktop or start menu

Uninstallation Instructions:
1. Run {self.app_name}_uninstaller.bat as Administrator
2. Follow the uninstallation process

Portable Version:
- No installation required
- Just run {self.app_name}.exe from the Portable folder
- All data will be stored in the same folder

System Requirements:
- Windows 10 or later
- Visual C++ Redistributable (usually pre-installed)

Generated: {time.strftime('%Y-%m-%d %H:%M:%S')}
'''
            
            readme_path = os.path.join(self.installer_dir, "README.txt")
            with open(readme_path, 'w', encoding='utf-8') as f:
                f.write(readme_content)
            
            self.print_success("Installer fayllar yaratildi!")
            return True
            
        except Exception as e:
            self.print_error(f"Installer fayllar yaratishda xatolik: {e}")
            return False
    
    def package_portable(self) -> bool:
        """Portable fayllarni alohida papkaga ko'chirish"""
        print("\n" + "=" * 60)
        print("🚀 Portable package yaratish...")
        print("=" * 60)
        
        if not os.path.exists(self.build_dir):
            print(f"❌ Build papkasi topilmadi: {self.build_dir}")
            return False
        
        try:
            target_dir = os.path.join(self.installer_dir, f"{self.app_name}_Portable")
            if os.path.exists(target_dir):
                shutil.rmtree(target_dir)
            shutil.copytree(self.build_dir, target_dir)
            print(f"✅ Portable fayllar ko'chirildi: {target_dir}")
            return True
        except Exception as e:
            print(f"❌ Portable fayllar ko'chirishda xatolik: {e}")
            return False

    def package_zip(self) -> bool:
        """ZIP arxiv yaratish (portable versiyani ZIPga o'rash)"""
        print("\n" + "=" * 60)
        print("🚀 ZIP package yaratish...")
        print("=" * 60)

        portable_dir = os.path.join(self.installer_dir, f"{self.app_name}_Portable")
        zip_path = os.path.join(self.installer_dir, f"{self.app_name}_Portable.zip")

        if not os.path.exists(portable_dir):
            print(f"❌ Portable papka topilmadi: {portable_dir}")
            return False
        
        try:
            if os.path.exists(zip_path):
                os.unlink(zip_path)

            with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
                for root, _, files in os.walk(portable_dir):
                    for file in files:
                        file_path = os.path.join(root, file)
                        arcname = os.path.relpath(file_path, portable_dir)
                        zipf.write(file_path, arcname)

            print(f"✅ ZIP fayl yaratildi: {zip_path}")
            return True
        except Exception as e:
            print(f"❌ ZIP yaratishda xatolik: {e}")
            return False
    
    def check_build_exists(self):
        """Build papkasi mavjudligini tekshirish"""
        self.print_step("Build papkasi mavjudligini tekshirish...")
        
        if self.build_dir and os.path.exists(self.build_dir):
            self.print_success(f"Build papkasi topildi: {self.build_dir}")
            
            # Build ichidagi fayllarni ko'rsatish
            try:
                files = os.listdir(self.build_dir)
                if files:
                    print(f"   Build fayllar: {', '.join(files[:5])}")
                    if len(files) > 5:
                        print(f"   ... va yana {len(files) - 5} ta fayl")
                else:
                    self.print_error("Build papkasi bo'sh!")
                    return False
            except Exception as e:
                self.print_error(f"Build papkasini o'qishda xatolik: {e}")
                return False
            
            return True
        else:
            self.print_error(f"Build papkasi topilmadi: {self.build_dir}")
            self.print_info("Avval 'flutter build windows --release' buyrug'ini bajaring")
            return False
    
    def find_build_directory(self):
        """Build papkasini topish"""
        self.print_step("Build papkasini qidirish...")
        
        possible_paths = [
            os.path.join(self.project_path, "build", "windows", "runner", "Release"),
            os.path.join(self.project_path, "build", "windows", "x64", "runner", "Release"),
            os.path.join(self.project_path, "build", "windows", "Release"),
        ]
        
        for path in possible_paths:
            if os.path.exists(path):
                self.build_dir = path
                self.print_success(f"Build papkasi topildi: {path}")
                return True
        
        self.print_error("Hech qaysi build papkasi topilmadi!")
        self.print_info("Quyidagi papkalar tekshirildi:")
        for path in possible_paths:
            print(f"   ❌ {path}")
        
        return False
    
    def run_full_process(self):
        """To'liq jarayonni ishga tushirish"""
        print(f"🎯 {self.app_name} uchun to'liq build jarayoni boshlanmoqda...")
        print(f"📂 Loyiha papkasi: {self.project_path}")
        
        # Flutter tekshirish - majburiy
        if not self.check_flutter_installation():
            self.print_error("Flutter topilmadi! Iltimos Flutter ni to'g'ri o'rnating va PATH ga qo'shing.")
            return False
        
        # Loyiha strukturasini tekshirish
        if not self.check_project_structure():
            return False
        
        # Build jarayoni
        steps = [
            ("Windows support yoqish", self.enable_windows_support),
            ("Dependencies olish", self.get_dependencies),
            ("Windows release build qilish", self.build_windows_release),
            ("Build papkasini topish", self.find_build_directory),
            ("Build mavjudligini tekshirish", self.check_build_exists),
            ("Installer fayllarini yaratish", self.create_installer_files),
            ("Portable package yaratish", self.package_portable),
            ("ZIP package yaratish", self.package_zip)
        ]
        
        failed_steps = []
        
        for step_name, step_function in steps:
            try:
                if not step_function():
                    failed_steps.append(step_name)
                    # Build topilmasa keyingi qadamlarni o'tkazib yuborish
                    if step_name in ["Build papkasini topish", "Build mavjudligini tekshirish"]:
                        self.print_error("Build topilmadi! Portable va ZIP yaratish o'tkazib yuboriladi.")
                        break
            except Exception as e:
                self.print_error(f"{step_name} da kutilmagan xatolik: {e}")
                failed_steps.append(step_name)
        
        # Natijalarni ko'rsatish
        print(f"\n{'='*80}")
        print(f"🎉 JARAYON YAKUNLANDI!")
        print(f"{'='*80}")
        
        if not failed_steps:
            print(f"✅ Barcha qadamlar muvaffaqiyatli bajarildi!")
        else:
            print(f"⚠️  Quyidagi qadamlarda xatoliklar bo'ldi:")
            for step in failed_steps:
                print(f"   - {step}")
        
        print(f"\n📁 Natijalar papkasi: {self.installer_dir}")
        print(f"📱 App nomi: {self.app_name}")
        
        # Build haqida ma'lumot
        if hasattr(self, 'build_dir') and self.build_dir and os.path.exists(self.build_dir):
            print(f"🔨 Build papkasi: {self.build_dir}")
        else:
            print(f"⚠️  Build papkasi topilmadi. Qo'lda build qiling:")
            print(f"   flutter build windows --release")
        
        # Yaratilgan fayllarni ko'rsatish
        if os.path.exists(self.installer_dir):
            print(f"\n📦 Yaratilgan fayllar:")
            for file in os.listdir(self.installer_dir):
                file_path = os.path.join(self.installer_dir, file)
                if os.path.isfile(file_path):
                    size = os.path.getsize(file_path) / (1024*1024)  # MB
                    print(f"   📄 {file} ({size:.2f} MB)")
                elif os.path.isdir(file_path):
                    print(f"   📁 {file}/")
        
        return len(failed_steps) == 0

def main():
    """Asosiy funksiya"""
    print("🚀 Flutter Setup & Windows Builder")
    print("=" * 50)
    
    # Loyiha papkasini so'rash
    if len(sys.argv) > 1:
        project_path = sys.argv[1]
    else:
        project_path = input("Flutter loyiha papkasini kiriting (bo'sh qoldirsa joriy papka): ").strip()
        if not project_path:
            project_path = os.getcwd()
    
    # Papka mavjudligini tekshirish
    if not os.path.exists(project_path):
        print(f"❌ Papka topilmadi: {project_path}")
        sys.exit(1)
    
    # Builder yaratish va ishga tushirish
    builder = FlutterSetupAndBuilder(project_path)
    
    success = builder.run_full_process()
    
    if success:
        print(f"\n🎉 Muvaffaqiyat! {builder.app_name} tayyor!")
        print(f"📂 Installer fayllar: {builder.installer_dir}")
        print(f"\n🔧 Keyingi qadamlar:")
        print(f"1. {builder.app_name}_installer.bat ni Administrator sifatida ishga tushiring")
        print(f"2. Yoki {builder.app_name}_Portable papkasidan to'g'ridan-to'g'ri ishga tushiring")
        sys.exit(0)
    else:
        print(f"\n❌ Ba'zi qadamlarda xatoliklar bo'ldi.")
        sys.exit(1)

if __name__ == "__main__":
    main()
