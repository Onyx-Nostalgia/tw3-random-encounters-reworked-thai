# RERThaiInstaller.spec
# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    ['installer_app/app.py'],
    pathex=['.'], # Use relative path if .spec file is in the project root
    binaries=[],
    datas=[
        ('installer_app/assets', 'installer_app/assets'),
        ('source_mods', 'source_mods'),
        ('installer_app/config.default.json', 'installer_app')
    ],
    hiddenimports=[],
    hookspath=[],
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)
pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='RERThaiInstaller',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True, # Try using UPX to reduce EXE size (if UPX is installed)
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False, # False for --windowed (no console)
    icon='installer_app/assets/RER-TH-mod-installer.ico', # Add custom icon
)
coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='RERThaiInstaller',
)
