import os
import shutil
import logging
from tkinter import messagebox, filedialog

import constants
import utils
import backup_utils

# Get logger instance
logger = logging.getLogger("ModInstallerApp") # Use the same logger as app.py

class ModInstallerLogic:
    def __init__(self, app_instance, destination_path_var, english_menu_var, status_label, ok_button, restore_button):
        """
        Initializes the logic handler with references to necessary UI elements and variables.
        """
        self.app_instance = app_instance # Reference to the main app window
        self.destination_path_var = destination_path_var
        self.english_menu_var = english_menu_var
        self.status_label = status_label
        self.ok_button = ok_button
        self.restore_button = restore_button # This button will be the "Uninstall" button

    def select_destination_folder(self):
        """
        Opens a system dialog to choose a directory and validates it.
        Updates the destination_path_var and status label.
        """
        folder_selected = filedialog.askdirectory()
        if folder_selected:
            if self.validate_game_path(folder_selected):
                self.destination_path_var.set(folder_selected) # This is correct, update the variable
                self.status_label.configure(
                    text="Game folder selected.",
                    text_color=constants.MONOKAI_TEXT_COLOR,
                    fg_color="transparent",
                )
            else:
                self.destination_path_var.set("")  # Clear if invalid
                utils.play_sound("error.wav", logger, is_system_sound=False)
                # Use app_instance to show status message
                utils.show_status_message(
                    self.app_instance, logger, self.status_label,
                    "❌ Invalid Game Folder. 'mods' , 'bin' or 'dlc' subfolder not found.",
                    constants.MONOKAI_ERROR_COLOR, "transparent", 3000
                )

    def validate_game_path(self, path_to_check):
        return utils.validate_game_path(path_to_check)

    def _perform_main_mod_installation(self, dest_path, dest_mods_folder, use_english_menu):
        """Handles the backup and installation of the main mod."""
        logger.info("--- Starting Main Mod Installation ---")
        if use_english_menu:
            source_main_mod_original_name = (
                "mod0RandomEncountersReworked_TH_(en_menu)"
            )
        else:
            source_main_mod_original_name = "mod0RandomEncountersReworked_TH_full"

        source_main_mod_path = utils.resource_path(
            os.path.join("source_mods", source_main_mod_original_name)
        )
        target_main_mod_renamed_name = "mod0RandomEncountersReworked_TH"
        target_main_mod_full_path = os.path.join(dest_mods_folder, target_main_mod_renamed_name)

        # Backup of the main mod before overwriting is removed as per new uninstall logic.
        # Uninstall will simply delete this mod.

        # Check if source main mod exists
        if not os.path.isdir(source_main_mod_path):
            logger.error(f"Source main mod not found: {source_main_mod_path}")
            # Raise an error that start_process can catch and display to the user
            raise FileNotFoundError(f"Source mod not found: {source_main_mod_path}")

        logger.info(
            f"⚙️ Preparing to install main mod from '{source_main_mod_path}' to '{target_main_mod_full_path}'"
        )
        if os.path.exists(target_main_mod_full_path):
            if os.path.isdir(target_main_mod_full_path):
                logger.info(
                    f"🗑️ Target directory '{target_main_mod_full_path}' exists. Removing it first."
                )
                shutil.rmtree(target_main_mod_full_path)
            else:
                logger.info(
                    f"🗑️ Target file '{target_main_mod_full_path}' exists. Removing it first."
                )
                os.remove(target_main_mod_full_path)

        shutil.copytree(source_main_mod_path, target_main_mod_full_path)
        logger.info(
            f"✅ Copied '{source_main_mod_original_name}' as '{target_main_mod_renamed_name}' successfully."
        )
        logger.info("--- Main Mod Installation Finished ---")
        return source_main_mod_path # Return for potential use in error messages

    def _perform_secondary_mod_installation(self, dest_mods_folder):
        """Handles the backup and installation of the secondary mod."""
        logger.info("--- Starting Secondary Mod Installation ---")
        source_secondary_mod_name = "modRandomEncountersReworked"
        source_secondary_mod_path = utils.resource_path(
            os.path.join("source_mods", source_secondary_mod_name)
        )
        target_secondary_mod_path = os.path.join(
            dest_mods_folder, source_secondary_mod_name
        )

        # --- One-time backup of the original modRandomEncountersReworked ---
        backup_dir = os.path.join(dest_mods_folder, "RER_Thai_Mod_Backups") # Standard backup location
        original_secondary_mod_backup_zip_path = os.path.join(backup_dir, constants.ORIGINAL_SECONDARY_MOD_BACKUP_FILENAME)

        if not os.path.exists(original_secondary_mod_backup_zip_path):
            if os.path.isdir(target_secondary_mod_path):
                logger.info(f"🛠️ Original '{source_secondary_mod_name}' found at '{target_secondary_mod_path}'. Performing one-time backup.")
                backup_utils.backup_full_directory_to_zip(
                    target_secondary_mod_path, original_secondary_mod_backup_zip_path, logger
                )
            else:
                logger.info(f"🛠️ No existing '{source_secondary_mod_name}' found at '{target_secondary_mod_path}'. Skipping one-time backup.")
        else:
            logger.info(f"🛠️ One-time backup for original '{source_secondary_mod_name}' already exists at '{original_secondary_mod_backup_zip_path}'. Skipping.")

        # Check if source secondary mod exists
        if not os.path.isdir(source_secondary_mod_path):
            logger.error(f"Source secondary mod (patch) not found: {source_secondary_mod_path}")
            # Raise an error that start_process can catch
            raise FileNotFoundError(f"Source patch not found: {source_secondary_mod_path}")

        logger.info(
            f"⚙️ Overlaying/updating with '{source_secondary_mod_path}' into '{target_secondary_mod_path}'"
        )
        shutil.copytree(
            source_secondary_mod_path, target_secondary_mod_path, dirs_exist_ok=True
        )
        logger.info(
            f"✅ Overlayed/updated '{source_secondary_mod_name}' successfully."
        )
        logger.info("--- Secondary Mod Installation Finished ---")
        return source_secondary_mod_path # Return for potential use in error messages

    def confirm_uninstall(self):
        """Confirms with the user before starting the uninstall process."""
        dest_path = self.destination_path_var.get()
        if not dest_path or not self.validate_game_path(dest_path):
            utils.play_sound("error.wav", logger, is_system_sound=False)
            utils.show_status_message(
                self.app_instance, logger, self.status_label, "Please select a valid Game Folder first.",
                constants.MONOKAI_ERROR_COLOR, "transparent", 3000
            )
            return

        # Ask for confirmation
        answer = messagebox.askyesno(
            title="Confirm Uninstall",
            message="This will attempt to restore the original 'modRandomEncountersReworked' (if a backup exists)\n"
                    "and remove 'mod0RandomEncountersReworked_TH'.\n\n"
                    "Are you sure you want to uninstall the RER Thai Mod?",
            icon=messagebox.WARNING # type: ignore
        )
        if answer:
            self.execute_uninstall()

    def execute_uninstall(self):
        """Performs the mod uninstallation process."""
        logger.info("--- Starting Uninstall Process ---")
        dest_path = self.destination_path_var.get()
        dest_mods_folder = os.path.join(dest_path, "mods")

        original_button_states = self.app_instance._ui_set_uninstalling_state()

        original_secondary_mod_restored = False
        main_thai_mod_removed = False
        uninstall_successful = False

        try:
            # 1. Restore Original Secondary Mod (modRandomEncountersReworked)
            secondary_mod_name = "modRandomEncountersReworked"
            target_secondary_mod_path = os.path.join(dest_mods_folder, secondary_mod_name)
            backup_dir = os.path.join(dest_mods_folder, "RER_Thai_Mod_Backups")
            original_secondary_mod_backup_zip_path = os.path.join(backup_dir, constants.ORIGINAL_SECONDARY_MOD_BACKUP_FILENAME)

            if os.path.exists(original_secondary_mod_backup_zip_path):
                logger.info(f"Attempting to restore original '{secondary_mod_name}' from '{original_secondary_mod_backup_zip_path}'.")
                if backup_utils.restore_from_zip(original_secondary_mod_backup_zip_path, target_secondary_mod_path, logger, pre_cleanup_path=target_secondary_mod_path):
                    original_secondary_mod_restored = True
                else:
                    logger.error(f"Failed to restore original '{secondary_mod_name}'.")
            else:
                logger.warning(f"Original backup for '{secondary_mod_name}' not found at '{original_secondary_mod_backup_zip_path}'. Cannot restore it.")
                original_secondary_mod_restored = True # Mark as true to allow overall success if main mod removal works.

            # 2. Remove Main Thai Mod (mod0RandomEncountersReworked_TH)
            main_thai_mod_name = "mod0RandomEncountersReworked_TH"
            target_main_thai_mod_path = os.path.join(dest_mods_folder, main_thai_mod_name)
            if os.path.isdir(target_main_thai_mod_path):
                logger.info(f"Removing main Thai mod: '{target_main_thai_mod_path}'.")
                shutil.rmtree(target_main_thai_mod_path)
                main_thai_mod_removed = True
                logger.info(f"Successfully removed '{target_main_thai_mod_path}'.")
            else:
                logger.info(f"Main Thai mod '{target_main_thai_mod_path}' not found. Nothing to remove.")
                main_thai_mod_removed = True # Considered success as the goal is for it to not be there.

            uninstall_successful = original_secondary_mod_restored and main_thai_mod_removed

            message_text = ""
            message_color = ""

            if uninstall_successful:
                message_text = "✓ Uninstall successful!"
                message_color = constants.MONOKAI_SUCCESS_COLOR
            else:
                message_text = "Uninstall completed with issues."
                if not original_secondary_mod_restored and os.path.exists(original_secondary_mod_backup_zip_path) :
                    message_text = "Error restoring original modRandomEncountersReworked."
                elif not main_thai_mod_removed:
                     message_text = "Error removing mod0RandomEncountersReworked_TH."
                message_color = constants.MONOKAI_ERROR_COLOR

            self.app_instance._ui_handle_uninstall_completion(
                original_button_states["install_text"],
                original_button_states["uninstall_text"],
                uninstall_successful,
                message_text,
                message_color
            )

        except Exception as e:
            logger.error(f"💥 Error during uninstall process: {e}", exc_info=True)
            self.app_instance._ui_handle_uninstall_completion(
                original_button_states["install_text"],
                original_button_states["uninstall_text"],
                success=False,
                message_text=f"Uninstall error: {str(e)}",
                message_color=constants.MONOKAI_ERROR_COLOR,
                duration_ms=5000
            )
        logger.info("--- Uninstall Process Finished ---")

    def start_process(self):
        """Starts the main mod installation process."""
        dest_path = self.destination_path_var.get()
        use_english_menu = self.english_menu_var.get()

        source_main_mod_path_for_error_check = ""
        source_secondary_mod_path_for_error_check = ""

        if not dest_path:
            utils.play_sound("error.wav", logger, is_system_sound=False)
            utils.show_status_message(
                self.app_instance, logger, self.status_label,
                "Please select the Game Folder.",
                constants.MONOKAI_ERROR_COLOR, "transparent", 3000
            )
            return

        if not self.validate_game_path(dest_path):
            utils.play_sound("error.wav", logger, is_system_sound=False)
            utils.show_status_message(
                self.app_instance, logger, self.status_label,
                "Invalid Game Folder. 'mods' subfolder not found.", # Corrected message
                constants.MONOKAI_ERROR_COLOR, "transparent", 3000
            )
            return

        original_button_text = self.app_instance._ui_set_installing_state()

        try:
            dest_mods_folder = os.path.join(dest_path, "mods")

            if not os.path.isdir(dest_mods_folder):
                self.app_instance._ui_handle_install_error(
                    original_button_text,
                    "Game Folder Invalid ('mods' subfolder not found).",
                    f"'mods' subfolder not found in validated path: {dest_mods_folder}"
                )
                return

            source_main_mod_path_for_error_check = self._perform_main_mod_installation(dest_path, dest_mods_folder, use_english_menu)
            source_secondary_mod_path_for_error_check = self._perform_secondary_mod_installation(dest_mods_folder)

            self.app_instance.save_config() # Save config on successful operation
            self.app_instance._ui_handle_install_success(original_button_text)

        except FileNotFoundError as fnf_error:
            error_message_display = f"Error: File not found - {os.path.basename(fnf_error.filename)}"
            if fnf_error.filename in [source_main_mod_path_for_error_check, source_secondary_mod_path_for_error_check]:
                error_message_display = f"Error: A required mod folder is missing: {os.path.basename(fnf_error.filename)}"
            self.app_instance._ui_handle_install_error(original_button_text, error_message_display, f"❌ FileNotFoundError: {fnf_error}", fnf_error)
        except PermissionError:
            self.app_instance._ui_handle_install_error(
                original_button_text,
                "Error: Permission denied. Try running as administrator.",
                "❌ PermissionError occurred. User may need to run as administrator."
            )
        except Exception as e:
            self.app_instance._ui_handle_install_error(
                original_button_text,
                f"An unexpected error occurred: {str(e)}",
                f"💥 An unexpected error occurred: {e}",
                e,
                exc_info=True
            )
