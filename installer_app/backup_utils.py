import os
import shutil
import zipfile
import logging # It's good practice for utility modules to have their own logger or accept one

# If this module needs its own logger instance:
# logger = logging.getLogger(__name__)
# logger.setLevel(logging.INFO) # Or as configured
# if not logger.hasHandlers():
#     ch_backup = logging.StreamHandler()
#     formatter_backup = logging.Formatter("%(asctime)s - [%(levelname)-7s] - (BackupUtils) %(message)s", datefmt="%Y-%m-%d %H:%M:%S")
#     ch_backup.setFormatter(formatter_backup)
#     logger.addHandler(ch_backup)

def backup_full_directory_to_zip(source_dir_path, backup_zip_file_path, logger):
    """
    Backs up the entire source_dir_path into a zip file at backup_zip_file_path.
    If the zip file already exists, it will be overwritten.
    """
    if not os.path.isdir(source_dir_path):
        logger.warning(f"🛠️ Source directory for full backup does not exist: {source_dir_path}")
        return False
    
    try:
        backup_zip_dir = os.path.dirname(backup_zip_file_path)
        if backup_zip_dir:
            os.makedirs(backup_zip_dir, exist_ok=True)
        
        if os.path.exists(backup_zip_file_path):
             logger.info(f"🛠️ Existing backup zip file found at '{backup_zip_file_path}'. Removing it before creating a new backup.")
             os.remove(backup_zip_file_path)

        logger.info(f"🛠️ Creating zip backup of '{source_dir_path}' to '{backup_zip_file_path}'.")
        with zipfile.ZipFile(backup_zip_file_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for root, _, files in os.walk(source_dir_path):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, source_dir_path)
                    zipf.write(file_path, arcname)
        
        logger.info(f"✅ Full directory backup: '{source_dir_path}' successfully backed up to '{backup_zip_file_path}'.")
        return True
    except Exception as e:
        logger.error(f"❌ Error during full directory backup of '{source_dir_path}' to '{backup_zip_file_path}': {e}")
        return False

# This function is currently not used due to the change in backup/uninstall logic.
# It backed up only files that would be overwritten by an incoming mod.
# The current logic uses a one-time full backup of the original secondary mod.
# def backup_overwritten_files_to_zip(source_dir_path, target_dir_path, backup_zip_file_path, logger):
#     """
#     Backs up files from target_dir_path that would be overwritten by files from source_dir_path
#     into a zip file at backup_zip_file_path.
#     The backup preserves the relative path structure within the zip file.
#     If the zip file already exists, it will be overwritten.
#     """
#     if not os.path.isdir(source_dir_path):
#         logger.warning(f"🛠️ Source directory for backup check does not exist: {source_dir_path}")
#         return
#     if not os.path.isdir(target_dir_path):
#         logger.info(f"🛠️ Target directory '{target_dir_path}' does not exist. No files to backup from it.")
#         return

#     files_to_backup = []
#     for root, _, files in os.walk(source_dir_path):
#         for filename in files:
#             relative_path_from_source_root = os.path.relpath(os.path.join(root, filename), source_dir_path)
#             target_file_full_path = os.path.join(target_dir_path, relative_path_from_source_root)
#             if os.path.isfile(target_file_full_path):
#                 files_to_backup.append((target_file_full_path, relative_path_from_source_root))

#     if not files_to_backup:
#         logger.info(f"🛠️ No files in '{target_dir_path}' required backup based on '{source_dir_path}'.")
#         if os.path.exists(backup_zip_file_path):
#             logger.info(f"🛠️ Removing obsolete backup zip: '{backup_zip_file_path}' as no files need backup this time.")
#             os.remove(backup_zip_file_path)
#         return

#     try:
#         backup_zip_dir = os.path.dirname(backup_zip_file_path)
#         if backup_zip_dir:
#             os.makedirs(backup_zip_dir, exist_ok=True)
        
#         if os.path.exists(backup_zip_file_path):
#              logger.info(f"🛠️ Existing backup zip file found at '{backup_zip_file_path}'. Removing it before creating a new backup.")
#              os.remove(backup_zip_file_path)

#         logger.info(f"🛠️ Creating zip backup for overwritten files. Target zip: '{backup_zip_file_path}'.")
#         with zipfile.ZipFile(backup_zip_file_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
#             for file_to_backup_path, arcname in files_to_backup:
#                 zipf.write(file_to_backup_path, arcname)
#                 logger.info(f"  🛡️ Added to zip backup: '{file_to_backup_path}' as '{arcname}'")
#         logger.info(f"✅ Backup of overwritten files completed. {len(files_to_backup)} file(s) backed up to '{backup_zip_file_path}'.")
#     except Exception as e:
#         logger.error(f"❌ Error creating zip backup for overwritten files at '{backup_zip_file_path}': {e}")

def restore_from_zip(backup_zip_path, extract_to_dir, logger, pre_cleanup_path=None):
    """
    Restores files from a backup zip file.
    If pre_cleanup_path is provided and exists, it will be removed before extraction.
    """
    if not os.path.exists(backup_zip_path):
        logger.error(f"🛡️❌ Backup file not found: {backup_zip_path}")
        return False

    try:
        if pre_cleanup_path and os.path.exists(pre_cleanup_path):
            if os.path.isdir(pre_cleanup_path):
                logger.info(f"🗑️ Removing existing directory before restore: {pre_cleanup_path}")
                shutil.rmtree(pre_cleanup_path)
            elif os.path.isfile(pre_cleanup_path): # Should not happen for mod directories
                logger.info(f"🗑️ Removing existing file before restore: {pre_cleanup_path}")
                os.remove(pre_cleanup_path)
        
        os.makedirs(extract_to_dir, exist_ok=True) # Ensure extraction directory exists

        logger.info(f"🛡️ Restoring from '{backup_zip_path}' to '{extract_to_dir}'...")
        with zipfile.ZipFile(backup_zip_path, 'r') as zipf:
            zipf.extractall(extract_to_dir)
        logger.info(f"✅ Successfully restored from '{backup_zip_path}' to '{extract_to_dir}'.")
        return True
    except Exception as e:
        logger.error(f"❌ Error during restore from '{backup_zip_path}': {e}")
        return False