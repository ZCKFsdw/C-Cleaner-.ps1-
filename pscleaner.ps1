# FreeSpace-Win11.ps1
# شغّل هذا الملف كـ Administrator
# يحذف مؤقتات آمنة ويعطي تقريراً عن المساحة الموفرة

Write-Host "== بدء تنظيف النظام ==" -ForegroundColor Cyan

# دالة لحساب المساحة الحرة قبل وبعد
function Get-FreeSpaceGB($drive="C:") {
    $d = Get-PSDrive -Name ($drive.TrimEnd(':')) -ErrorAction SilentlyContinue
    if ($d) { [math]::Round($d.Free/1GB,2) } else { 0 }
}

$before = Get-FreeSpaceGB "C:"
Write-Host "مساحة C: قبل التنظيف: $before GB" -ForegroundColor Yellow

# 1) حذف ملفات مؤقتة للمستخدم الحالي
$UserTemp = "$env:LOCALAPPDATA\Temp\*"
Write-Host "حذف ملفات المؤقت للمستخدم..." -ForegroundColor Gray
Try { Remove-Item -Path $UserTemp -Recurse -Force -ErrorAction SilentlyContinue } Catch {}

# 2) حذف محتويات مجلد Windows Update المؤقت
$wu = "C:\Windows\SoftwareDistribution\Download\*"
Write-Host "حذف Windows Update cache (SoftwareDistribution\Download)..." -ForegroundColor Gray
Try { Stop-Service -Name wuauserv -ErrorAction SilentlyContinue; Remove-Item -Path $wu -Recurse -Force -ErrorAction SilentlyContinue; Start-Service -Name wuauserv -ErrorAction SilentlyContinue } Catch {}

# 3) تنظيف مجلد Temp عام
$sysTemp = "C:\Windows\Temp\*"
Write-Host "حذف C:\Windows\Temp..." -ForegroundColor Gray
Try { Remove-Item -Path $sysTemp -Recurse -Force -ErrorAction SilentlyContinue } Catch {}

# 4) إفراغ سلة المحذوفات
Write-Host "إفراغ سلة المحذوفات..." -ForegroundColor Gray
Try {
    $shell = New-Object -ComObject Shell.Application
    $shell.Namespace(0x0a).Items() | ForEach-Object { $shell.Namespace(0x0a).InvokeVerb("empty") }
} Catch {}

# 5) تشغيل أداة تنظيف مكونات ويندوز (StartComponentCleanup) و ResetBase
Write-Host "تشغيل DISM لتنظيف مكونات ويندوز (قد يأخذ وقتاً)..." -ForegroundColor Gray
Try {
    dism /online /Cleanup-Image /StartComponentCleanup | Out-Null
    dism /online /Cleanup-Image /StartComponentCleanup /ResetBase | Out-Null
} Catch {}

# 6) إيقاف الإسبات (يحذف hiberfil.sys) — سيفضي مساحة كبيرة عادةً
Write-Host "إيقاف الإسبات (Hibernate) لتوفير المساحة. لإعادة التشغيل: powercfg -h on" -ForegroundColor Gray
Try { powercfg -h off } Catch {}

# 7) تقرير نهائي
$after = Get-FreeSpaceGB "C:"
Write-Host "مساحةs C: بعد التنظيف: $after GB" -ForegroundColor Green
$freed = [math]::Round(($after - $before),2)
Write-Host "المجموع المحفوظ (تقريبي): $freed GB" -ForegroundColor Magenta

Write-Host "== انتهى التنظيف. راجع النتائج وإذا تبقى حاجة لمساحة أكبر ننتقل لخطوات إضافية ==" -ForegroundColor Cyan
