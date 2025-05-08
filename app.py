import customtkinter
import tkinter
from tkinter import messagebox # For confirmation dialog
from tkinter import filedialog
import os  # Needed for path operations
import shutil  # Needed for file/folder copying
import logging  # For logging
import json  # For handling config file
import datetime # For timestamped backups
import constants  # Assuming constants.py is in the same directory
from PIL import Image  # For loading icon image
import utils  # Assuming utils.py is in the same directory
import backup_utils # For backup functionalities

# --- Logger Setup ---
# Create a logger
logger = logging.getLogger("ModInstallerApp")
logger.setLevel(
    logging.INFO
)  # Set to DEBUG to catch all levels, can be changed to INFO for production

# Create a console handler and set its level
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)  # Or INFO for less verbose output

# Create a formatter and add it to the handler
formatter = logging.Formatter(
    "%(asctime)s - [%(levelname)-7s] - %(message)s", datefmt="%Y-%m-%d %H:%M:%S"
)
ch.setFormatter(formatter)

# Add the handler to the logger
if (
    not logger.hasHandlers()
):  # Avoid adding multiple handlers if script is re-run in some environments
    logger.addHandler(ch)


class ModInstallerApp(customtkinter.CTk):

    def __init__(self):
        super().__init__()

        # For Windows Taskbar Icon with overrideredirect
        self._style_set = False
        if os.name == "nt":  # Only on Windows
            from ctypes import windll

        # --- Application Setup ---
        self.title(
            f"RER Thai Mod Installer {constants.APP_VERSION}"
        )  # Title will be set in custom title bar
        # Increased height to better display status/error messages
        self.geometry("600x360")  # Adjusted height

        customtkinter.set_appearance_mode(
            "dark"
        )  # Ensure dark mode is globally set for customtkinter

        # --- Set Application Icon ---
        try:
            # Construct the path to the icon file relative to the script's location
            script_dir = os.path.dirname(os.path.abspath(__file__))
            icon_path = os.path.join(script_dir, "assets", "RER_thai.ico")
            self.iconbitmap(icon_path)
            self.update_idletasks()
        except Exception as e:
            logger.error(f"🎨❌ Error setting application icon: {e}")

        # Remove default OS title bar
        self.overrideredirect(True)

        # Variables for window dragging
        self._offset_x = 0
        self._offset_y = 0

        # Create custom title bar first
        self._create_custom_title_bar()

        # Configure main window background color
        self.configure(fg_color=constants.MONOKAI_MAIN_BG)

        # --- Application Variables ---
        self.destination_path_var = (
            tkinter.StringVar()
        )  # Variable to store the selected destination path
        self.english_menu_var = (
            tkinter.BooleanVar()
        )  # Variable to store the state of the English menu checkbox

        # Load config on startup
        self.load_config()
        self.protocol("WM_DELETE_WINDOW", self.on_closing)  # Save config on close

        # --- UI Elements ---
        # Create a main frame for content with padding
        self.main_frame = customtkinter.CTkFrame(self, fg_color="transparent")
        self.main_frame.pack(
            pady=(0, 20), padx=25, fill="both", expand=True
        )  # Adjusted pady top

        # --- Destination Path Selection ---
        self.path_label = customtkinter.CTkLabel(
            self.main_frame,
            text="Game Folder:",
            text_color=constants.MONOKAI_TEXT_COLOR,
            font=customtkinter.CTkFont(
                family="Segoe UI", size=16
            ),  # Increased font size
        )
        self.path_label.pack(pady=(0, 5), anchor="w")  # Anchor to west (left)

        # Frame to hold path entry and browse button horizontally
        self.path_controls_frame = customtkinter.CTkFrame(
            self.main_frame, fg_color="transparent"
        )
        self.path_controls_frame.pack(fill="x", pady=(0, 20))

        self.path_entry = customtkinter.CTkEntry(
            self.path_controls_frame,
            textvariable=self.destination_path_var,
            state="readonly",  # User cannot type directly, must use browse button
            fg_color=constants.MONOKAI_ELEMENT_BG,
            border_color=constants.MONOKAI_ELEMENT_BORDER,
            text_color=constants.MONOKAI_TEXT_COLOR,
            font=customtkinter.CTkFont(
                family="Segoe UI", size=14
            ),  # Increased font size
            height=35,  # Adjusted height
        )
        self.path_entry.pack(side="left", fill="x", expand=True, padx=(0, 10))
        # Make the path entry clickable to open the folder dialog
        self.path_entry.bind(
            "<Button-1>", lambda event: self.select_destination_folder()
        )

        self.browse_button = customtkinter.CTkButton(
            self.path_controls_frame,
            text="Browse",
            command=self.select_destination_folder,
            fg_color=constants.MONOKAI_ELEMENT_BG,
            text_color=constants.MONOKAI_TEXT_COLOR,
            hover_color=constants.MONOKAI_ACCENT_YELLOW,  # Highlight with yellow on hover
            # text_color_on_hover is not a direct CTkButton attribute,
            # constants.MONOKAI_TEXT_COLOR should be readable on constants.MONOKAI_ACCENT_YELLOW.
            border_color=constants.MONOKAI_ELEMENT_BORDER,
            border_width=1,
            font=customtkinter.CTkFont(
                family="Segoe UI", size=14, weight="bold"
            ),  # Increased font size
            height=35,  # Adjusted height to match OK button
        )
        self.browse_button.pack(side="left")

        # --- English Menu Checkbox ---
        self.english_menu_checkbox = customtkinter.CTkCheckBox(
            self.main_frame,
            text="English Menu Version",
            variable=self.english_menu_var,
            text_color=constants.MONOKAI_TEXT_COLOR,
            font=customtkinter.CTkFont(
                family="Segoe UI", size=16
            ),  # Increased font size
            fg_color=constants.MONOKAI_ACCENT_YELLOW,  # Color of the checkbox itself when checked
            hover_color=constants.MONOKAI_ACCENT_YELLOW_HOVER,  # Hover color for the checkbox
            checkmark_color=constants.MONOKAI_MAIN_BG,  # Color of the check mark symbol (dark on yellow)
        )
        self.english_menu_checkbox.pack(pady=15, anchor="w")

        # --- OK Button ---
        self.ok_button = customtkinter.CTkButton(
            self.main_frame,
            text="Install",
            command=self.start_process,
            fg_color=constants.MONOKAI_ACCENT_YELLOW,  # Prominent yellow for the main action button
            text_color=constants.MONOKAI_MAIN_BG,  # Dark text for contrast on yellow button
            hover_color=constants.MONOKAI_ACCENT_YELLOW_HOVER,  # Lighter yellow for hover
            font=customtkinter.CTkFont(
                family="Segoe UI", size=16, weight="bold"
            ),  # Increased font size
            height=35,  # Adjusted height
        )
        self.ok_button.pack(pady=20, fill="x")

        # --- Restore Button ---
        self.restore_button = customtkinter.CTkButton(
            self.main_frame,
            text="Restore Backup",
            command=self.confirm_restore_backup,
            fg_color=constants.MONOKAI_ELEMENT_BG, # Less prominent than install
            text_color=constants.MONOKAI_TEXT_COLOR,
            hover_color=constants.MONOKAI_ACCENT_YELLOW_HOVER,
            border_color=constants.MONOKAI_ELEMENT_BORDER,
            border_width=1,
            font=customtkinter.CTkFont(
                family="Segoe UI", size=16, weight="bold"
            ),
            height=35,
        )
        self.restore_button.pack(pady=(0,10), fill="x") # Place it below the Install button

        # --- Status Label ---
        self.status_label = customtkinter.CTkLabel(
            self.main_frame,
            text="",  # Initially empty
            font=customtkinter.CTkFont(
                family="Segoe UI", size=16, weight="bold"
            ),  # Increased font size
            # text_color will be set dynamically
        )
        self.status_label.configure(width=250)  # Set a moderate fixed width
        self.status_label.pack(
            pady=10, ipady=8
        )  # Increased ipady for a taller box, removed fill="x"

    def _create_custom_title_bar(self):
        self.title_bar_frame = customtkinter.CTkFrame(
            self, height=35, fg_color=constants.MONOKAI_ELEMENT_BG, corner_radius=0
        )
        self.title_bar_frame.pack(side="top", fill="x")

        # --- Add Icon to Custom Title Bar ---
        try:
            script_dir = os.path.dirname(os.path.abspath(__file__))
            # Use a .png or a small .ico for display. Large .ico might not render well.
            # Let's assume you have a 'RER_thai_32.png' or similar for the title bar.
            icon_display_path = os.path.join(
                script_dir, "assets", "RER_thai.ico"
            )  # Or a PNG version
            if os.path.exists(icon_display_path):
                ctk_icon_image = customtkinter.CTkImage(
                    light_image=Image.open(icon_display_path),
                    dark_image=Image.open(icon_display_path),
                    size=(30, 30),
                )  # Adjust size as needed
                self.icon_label_titlebar = customtkinter.CTkLabel(
                    self.title_bar_frame, image=ctk_icon_image, text=""
                )
                self.icon_label_titlebar.pack(
                    side="left", padx=(5, 0), pady=5
                )  # Pack before title
        except Exception as e:
            logger.error(f"🎨❌ Error loading icon for title bar: {e}")

        # Bind events for dragging the window
        self.title_bar_frame.bind("<ButtonPress-1>", self._on_title_bar_press)
        self.title_bar_frame.bind("<B1-Motion>", self._on_title_bar_motion)

        # Close Button
        close_button = customtkinter.CTkButton(
            self.title_bar_frame,
            text="✕",  # Close symbol
            command=self.on_closing,
            width=35,
            height=35,
            fg_color="transparent",  # Transparent background
            text_color=constants.MONOKAI_TEXT_COLOR,
            hover_color=constants.MONOKAI_ERROR_PINK,  # Reddish hover for close
            font=customtkinter.CTkFont(family="Segoe UI", size=16, weight="bold"),
            corner_radius=0,
        )
        close_button.pack(side="right", padx=(0, 0))

        # Minimize Button
        minimize_button = customtkinter.CTkButton(
            self.title_bar_frame,
            text="—",  # Minimize symbol
            command=self.minimize_window,  # Changed to custom minimize handler
            width=35,
            height=35,
            fg_color="transparent",
            text_color=constants.MONOKAI_TEXT_COLOR,
            hover_color=constants.MONOKAI_ELEMENT_BORDER,  # Subtle hover
            font=customtkinter.CTkFont(family="Segoe UI", size=16, weight="bold"),
            corner_radius=0,
        )
        minimize_button.pack(side="right", padx=(0, 0))

        # Application Title Label
        self.title_label = customtkinter.CTkLabel(  # Store as instance variable
            self.title_bar_frame,
            text=f"RER Thai Mod Installer {constants.APP_VERSION}",
            text_color=constants.MONOKAI_TEXT_COLOR,
            font=customtkinter.CTkFont(family="Segoe UI", size=14, weight="bold"),
        )
        self.title_label.pack(side="left", padx=10, pady=5)
        # Also bind drag events to the title label
        self.title_label.bind("<ButtonPress-1>", self._on_title_bar_press)
        self.title_label.bind("<B1-Motion>", self._on_title_bar_motion)

    def _on_title_bar_press(self, event):
        # Record the mouse position relative to the window's top-left corner
        self._offset_x = event.x
        self._offset_y = event.y

    def _on_title_bar_motion(self, event):
        # Calculate new window position and move the window
        new_x = self.winfo_x() + (event.x - self._offset_x)
        new_y = self.winfo_y() + (event.y - self._offset_y)
        self.geometry(f"+{new_x}+{new_y}")

    def minimize_window(self):
        if os.name == "nt":  # Only attempt this on Windows
            try:
                from ctypes import windll

                # The HWND that has the taskbar icon and is managed by the OS
                # is typically the parent of the overrideredirect Tkinter window.
                # This is the same HWND we modified the style for earlier.
                hwnd_to_minimize = windll.user32.GetParent(self.winfo_id())

                if hwnd_to_minimize:  # Ensure hwnd is not NULL (0)
                    SW_MINIMIZE = 6  # Flag to minimize the window
                    # Tell Windows to minimize this window.
                    # Windows should then handle its taskbar icon appropriately.
                    windll.user32.ShowWindow(hwnd_to_minimize, SW_MINIMIZE)
                    # print(f"Minimize: ShowWindow API called for HWND {hwnd_to_minimize}") # For debugging
                else:  # pragma: no cover
                    # This would be unusual if the taskbar icon hack worked.
                    logger.error(
                        "❌ Minimize Error: Could not get parent HWND via GetParent(self.winfo_id()). Cannot use Windows API to minimize."
                    )
            except Exception as e:  # pragma: no cover
                logger.error(f"❌ Error during Windows API minimize attempt: {e}")
        else:
            # For non-Windows systems, Tkinter's iconify will raise an error with overrideredirect.
            # This is to show the original error if not on Windows.
            super().iconify()

    def show_success_popup(self):
        # Create a Toplevel window for the success message
        success_popup = customtkinter.CTkToplevel(self)
        success_popup.title("")  # No title for a simple popup
        success_popup.geometry("250x100")  # Adjust size as needed
        success_popup.resizable(False, False)  # type: ignore
        success_popup.configure(fg_color=constants.MONOKAI_MAIN_BG)

        # Center the popup on the main window
        # Get main window position and size
        main_x = self.winfo_x()
        main_y = self.winfo_y()
        main_width = self.winfo_width()
        main_height = self.winfo_height()
        # Calculate position for popup
        popup_x = main_x + (main_width // 2) - (250 // 2)  # 250 is popup width
        popup_y = main_y + (main_height // 2) - (100 // 2)  # 100 is popup height
        success_popup.geometry(f"+{popup_x}+{popup_y}")

        success_label = customtkinter.CTkLabel(
            success_popup,
            text="Installation Successful!",
            font=customtkinter.CTkFont(family="Segoe UI", size=16, weight="bold"),
            text_color=constants.MONOKAI_SUCCESS_GREEN,
        )
        success_label.pack(expand=True, pady=20)

        success_popup.after(
            2500, success_popup.destroy
        )  # Close popup after 2.5 seconds

    def select_destination_folder(self):
        # This function is called when the "เลือกโฟลเดอร์" (Browse) button is clicked.
        # It opens a system dialog to choose a directory.
        folder_selected = filedialog.askdirectory()
        if folder_selected:
            if self.validate_game_path(folder_selected):
                self.destination_path_var.set(folder_selected)
                self.status_label.configure(
                    text="Game folder selected.",
                    text_color=constants.MONOKAI_TEXT_COLOR,
                    fg_color="transparent",
                )
            else:
                self.destination_path_var.set("")  # Clear if invalid
                utils.play_sound("error.wav", logger, is_system_sound=False)
                self.status_label.configure(
                    text="❌ Invalid Game Folder. 'mods' , 'bin' or 'dlc' subfolder not found.",
                    text_color=constants.MONOKAI_ERROR_PINK,
                    fg_color="transparent",
                )

    def validate_game_path(self, path_to_check):
        # Basic validation: check for 'mods' and 'bin' subfolders
        # You can customize this further for your specific game
        if not path_to_check or not os.path.isdir(path_to_check):
            return False

        has_folders = ["mods", "bin", "dlc"]
        for folder in has_folders:
            if not os.path.isdir(os.path.join(path_to_check, folder)):
                return False
        return True  # All required folders exist

    def on_closing(self):
        # This method is called when the window is closed.
        try:
            self.save_config()
            # Attempt to unbind events to prevent errors after widget destruction
            if hasattr(self, "title_bar_frame") and self.title_bar_frame.winfo_exists():
                self.title_bar_frame.unbind("<ButtonPress-1>")
                self.title_bar_frame.unbind("<B1-Motion>")
            # TODO: Add unbinding for title_label if it exists and is bound
        except Exception as e:
            logger.error(f"🧹❌ Error during pre-closing cleanup: {e}")
        finally:  # pragma: no cover
            self.destroy()  # Ensure destroy is called

    def _perform_main_mod_installation(self, script_dir, dest_path, dest_mods_folder, use_english_menu):
        """Handles the backup and installation of the main mod."""
        logger.info("--- Starting Main Mod Installation ---")
        if use_english_menu:
            source_main_mod_original_name = (
                "mod0RandomEncountersReworked_TH_(en_menu)"
            )
        else:
            source_main_mod_original_name = "mod0RandomEncountersReworked_TH_full"

        source_main_mod_path = os.path.join(
            script_dir, "mods", source_main_mod_original_name
        )
        target_main_mod_renamed_name = "mod0RandomEncountersReworked_TH"
        target_main_mod_full_path = os.path.join(
            dest_mods_folder, target_main_mod_renamed_name
        )

        # Backup Main Mod (if exists) before removal
        if os.path.isdir(target_main_mod_full_path):
            logger.info(f"🛡️ Existing main mod found at '{target_main_mod_full_path}'. Performing full backup.")
            main_mod_backup_root = os.path.join(dest_mods_folder, "RER_Thai_Mod_Backups")
            main_mod_backup_zip_file = os.path.join(main_mod_backup_root, f"{target_main_mod_renamed_name}.zip")
            backup_utils.backup_full_directory_to_zip(
                target_main_mod_full_path, main_mod_backup_zip_file, logger
            )

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

    def _perform_secondary_mod_installation(self, script_dir, dest_mods_folder):
        """Handles the backup and installation of the secondary mod."""
        logger.info("--- Starting Secondary Mod Installation ---")
        source_secondary_mod_name = "modRandomEncountersReworked"
        source_secondary_mod_path = os.path.join(
            script_dir, "mods", source_secondary_mod_name
        )
        target_secondary_mod_path = os.path.join(
            dest_mods_folder, source_secondary_mod_name
        )

        # Backup files from Secondary Mod that will be overwritten
        secondary_mod_backup_root = os.path.join(dest_mods_folder, "RER_Thai_Mod_Backups")
        secondary_mod_backup_zip_file = os.path.join(secondary_mod_backup_root, f"{source_secondary_mod_name}.zip")
        backup_utils.backup_overwritten_files_to_zip(source_secondary_mod_path, target_secondary_mod_path, secondary_mod_backup_zip_file, logger)

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

    def confirm_restore_backup(self):
        dest_path = self.destination_path_var.get()
        if not dest_path or not self.validate_game_path(dest_path):
            utils.play_sound("error.wav", logger, is_system_sound=False)
            utils.show_status_message(
                self, logger, self.status_label, "Please select a valid Game Folder first.",
                constants.MONOKAI_ERROR_PINK, "transparent", 3000
            )
            return

        # Check if backup files exist (basic check for now)
        dest_mods_folder = os.path.join(dest_path, "mods")
        backup_root = os.path.join(dest_mods_folder, "RER_Thai_Mod_Backups")
        main_mod_backup_zip = os.path.join(backup_root, "mod0RandomEncountersReworked_TH.zip")
        secondary_mod_backup_zip = os.path.join(backup_root, "modRandomEncountersReworked.zip")

        if not os.path.exists(main_mod_backup_zip) and not os.path.exists(secondary_mod_backup_zip):
            utils.play_sound("error.wav", logger, is_system_sound=False)
            utils.show_status_message(
                self, logger, self.status_label, "No backup files found to restore.",
                constants.MONOKAI_ERROR_PINK, "transparent", 3000
            )
            return

        # Ask for confirmation
        answer = messagebox.askyesno(
            title="Confirm Restore",
            message="This will restore your mods from the last backup.\nAny changes made after the backup might be lost.\n\nAre you sure you want to proceed?",
            icon=messagebox.WARNING # type: ignore
        )
        if answer:
            self.execute_restore_backup()

    def execute_restore_backup(self):
        logger.info("--- Starting Backup Restore Process ---")
        dest_path = self.destination_path_var.get()
        dest_mods_folder = os.path.join(dest_path, "mods")
        backup_root = os.path.join(dest_mods_folder, "RER_Thai_Mod_Backups")

        original_install_button_text = self.ok_button.cget("text")
        original_restore_button_text = self.restore_button.cget("text")

        self.ok_button.configure(state="disabled")
        self.restore_button.configure(text="Restoring...", state="disabled", text_color_disabled=constants.MONOKAI_MAIN_BG)
        self.status_label.configure(text="")
        self.update_idletasks()

        main_mod_restored = False
        secondary_mod_restored = False

        try:
            # Restore Main Mod
            main_mod_name = "mod0RandomEncountersReworked_TH"
            main_mod_backup_zip = os.path.join(backup_root, f"{main_mod_name}.zip")
            target_main_mod_path = os.path.join(dest_mods_folder, main_mod_name)
            if os.path.exists(main_mod_backup_zip):
                logger.info(f"Attempting to restore Main Mod: {main_mod_name}")
                if backup_utils.restore_from_zip(main_mod_backup_zip, target_main_mod_path, logger, pre_cleanup_path=target_main_mod_path):
                    main_mod_restored = True
                else:
                    logger.error(f"Failed to restore Main Mod from {main_mod_backup_zip}")
            else:
                logger.warning(f"Main Mod backup not found: {main_mod_backup_zip}")

            # Restore Secondary Mod
            secondary_mod_name = "modRandomEncountersReworked"
            secondary_mod_backup_zip = os.path.join(backup_root, f"{secondary_mod_name}.zip")
            target_secondary_mod_path = os.path.join(dest_mods_folder, secondary_mod_name) # Extract directly into this folder
            if os.path.exists(secondary_mod_backup_zip):
                logger.info(f"Attempting to restore Secondary Mod: {secondary_mod_name}")
                if backup_utils.restore_from_zip(secondary_mod_backup_zip, target_secondary_mod_path, logger): # No pre_cleanup_path, just overlay
                    secondary_mod_restored = True
                else:
                    logger.error(f"Failed to restore Secondary Mod from {secondary_mod_backup_zip}")
            else:
                logger.warning(f"Secondary Mod backup not found: {secondary_mod_backup_zip}")

            if main_mod_restored or secondary_mod_restored:
                utils.play_sound("done.wav", logger, is_system_sound=False) # Use done sound for success
                utils.show_status_message(self, logger, self.status_label, "✓ Backup restored successfully!", constants.MONOKAI_SUCCESS_GREEN, "transparent", 3000)
            else:
                utils.play_sound("error.wav", logger, is_system_sound=False)
                utils.show_status_message(self, logger, self.status_label, "No backup files found or restore failed.", constants.MONOKAI_ERROR_PINK, "transparent", 4000)

        except Exception as e:
            logger.error(f"💥 Error during restore process: {e}", exc_info=True)
            utils.play_sound("error.wav", logger, is_system_sound=False)
            utils.show_status_message(self, logger, self.status_label, f"Restore error: {str(e)}", constants.MONOKAI_ERROR_PINK, "transparent", 5000)
        finally:
            self.ok_button.configure(state="normal") # Re-enable install button
            self.restore_button.configure(text=original_restore_button_text, state="normal")
            logger.info("--- Backup Restore Process Finished ---")

    def start_process(self):
        # This function is called when the "ตกลง" (OK) button is clicked.
        dest_path = self.destination_path_var.get()  # Get the selected destination path
        use_english_menu = self.english_menu_var.get()  # Get the state of the checkbox

        # Initialize paths that might be used in error messages, even if installation fails early
        # These will be properly set if the respective installation part is reached
        # This is a bit of a workaround to ensure fnf_error.filename can be checked later
        # A more robust solution might involve a custom exception class carrying more context.
        source_main_mod_path_for_error_check = ""
        source_secondary_mod_path_for_error_check = ""

        if not dest_path:
            utils.play_sound("error.wav", logger, is_system_sound=False)
            self.status_label.configure(
                text="Please select the Game Folder.",
                text_color=constants.MONOKAI_ERROR_PINK,
                fg_color="transparent",
            )  # Ensure transparent bg for error
            return

        # Re-validate before processing, in case path was set manually or changed
        if not self.validate_game_path(dest_path):
            utils.play_sound("error.wav", logger, is_system_sound=False)
            self.status_label.configure(
                text="Invalid Game Folder. 'mods' subfolder not found.",
                text_color=constants.MONOKAI_ERROR_PINK,
                fg_color="transparent",
            )
            return

        # --- Update UI to show "Installing..." ---
        original_button_text = self.ok_button.cget("text")  # Store original text
        self.ok_button.configure(
            text="Installing...",
            state="disabled",
            text_color_disabled=constants.MONOKAI_MAIN_BG,
        )  # Ensure disabled text color is set
        self.status_label.configure(text="")  # Clear previous status
        self.update_idletasks()  # Force UI update before blocking operations

        self.restore_button.configure(state="disabled") # Disable restore button during install
        # --- Actual Mod Installation Process ---
        try:
            script_dir = os.path.dirname(
                os.path.abspath(__file__)
            )  # Get the directory where the script is located

            dest_mods_folder = os.path.join(
                dest_path, "mods"
            )  # Target 'mods' folder in the game directory



            # Check if the base 'mods' folder exists in the destination
            # This check is somewhat redundant due to validate_game_path, but kept for safety.
            if not os.path.isdir(dest_mods_folder):
                utils.play_sound("error.wav", logger, is_system_sound=False)
                self.status_label.configure(
                    text="Game Folder Invalid ('mods' subfolder not found).",  # Changed text
                    text_color=constants.MONOKAI_ERROR_PINK,
                    fg_color="transparent",
                )
                self.ok_button.configure(
                    text=original_button_text, state="normal"
                )  # Reset button
                return

            # --- Part 1: Install Main Mod ---
            source_main_mod_path_for_error_check = self._perform_main_mod_installation(script_dir, dest_path, dest_mods_folder, use_english_menu)

            # --- Part 2: Install Secondary Mod ---
            source_secondary_mod_path_for_error_check = self._perform_secondary_mod_installation(script_dir, dest_mods_folder)


            # --- Animate button to success state and back ---
            self.save_config()  # Save config on successful operation

            # Phase 1: Transition to "Done" state
            # Button is already disabled from "Installing..."
            # Set text and the crucial text_color_disabled for the "Done" appearance
            self.ok_button.configure(
                text="✓ Done!", text_color_disabled=constants.MONOKAI_TEXT_COLOR
            )  # Set disabled text to white

            # Animate fg_color to green. text_color will also be animated to white.
            # Since button is disabled, text_color_disabled (set above) will be primarily visible.
            utils.animate_widget_color(
                self,
                logger,
                self.ok_button,
                constants.MONOKAI_SUCCESS_GREEN,
                constants.MONOKAI_TEXT_COLOR,
                "✓ Done!",
                15,  # Animate text_color to white
                callback=lambda: utils.play_sound(
                    "done.wav", logger, is_system_sound=False
                ),
            )

            utils.animate_widget_color(
                self,
                logger,
                self.title_bar_frame,
                constants.MONOKAI_SUCCESS_GREEN,
                None,
                None,
                15,
            )  # Animate title bar bg
            utils.animate_widget_color(
                self,
                logger,
                self.title_label,
                None,
                constants.MONOKAI_MAIN_BG,
                None,
                15,
            )  # Animate title label text color

            # Callback chain for returning to normal state
            def return_to_normal_state_setup():
                # Button is still disabled.
                # Phase 2: Transition back to "Install" state
                # Set text and text_color_disabled for the "Install" appearance while animating back.
                # constants.MONOKAI_MAIN_BG should be a good disabled text color for a yellow button background.
                self.ok_button.configure(
                    text=original_button_text,
                    text_color_disabled=constants.MONOKAI_MAIN_BG,
                )

                # Animate fg_color back to yellow, text_color back to main_bg.
                utils.animate_widget_color(
                    self,
                    logger,
                    self.ok_button,
                    constants.MONOKAI_ACCENT_YELLOW,
                    constants.MONOKAI_MAIN_BG,
                    original_button_text,
                    15,
                    callback=lambda: self.ok_button.configure(state="normal"),
                )  # Finally, enable the button
                utils.animate_widget_color(
                    self,
                    logger,
                    self.title_bar_frame,
                    constants.MONOKAI_ELEMENT_BG,
                    None,
                    None,
                    15,
                )  # Animate title bar bg back
                utils.animate_widget_color(
                    self,
                    logger,
                    self.title_label,
                    None,
                    constants.MONOKAI_TEXT_COLOR,
                    None,
                    15,
                )  # Animate title label text color back

            # Hold "Done" state. Animation to "Done" takes (15*30)ms.
            # Hold for 1500ms *after* the animation to "Done" is complete.
            animation_duration_ms = 15 * 30
            hold_duration_ms = 1500
            self.after(
                animation_duration_ms + hold_duration_ms, return_to_normal_state_setup
            )

        except FileNotFoundError as fnf_error:
            self.ok_button.configure(text=original_button_text, state="normal")
            error_message = (
                f"Error: File not found - {os.path.basename(fnf_error.filename)}"
            )
            if fnf_error.filename in [source_main_mod_path_for_error_check, source_secondary_mod_path_for_error_check]:
                error_message = f"Error: A required mod folder is missing: {os.path.basename(fnf_error.filename)}"
            # Show error message (currently text-only, no background fade-in)
            utils.play_sound(
                "error.wav", logger, is_system_sound=False
            )  # Play custom error sound
            utils.show_status_message(
                self,
                logger,
                self.status_label,
                error_message,
                constants.MONOKAI_ERROR_PINK,
                "transparent",
                5000,
            )
            logger.error(f"❌ FileNotFoundError: {fnf_error}")
        except PermissionError:
            self.ok_button.configure(text=original_button_text, state="normal")
            utils.play_sound(
                "error.wav", logger, is_system_sound=False
            )  # Play custom error sound
            utils.show_status_message(
                self,
                logger,
                self.status_label,
                "Error: Permission denied. Try running as administrator.",
                constants.MONOKAI_ERROR_PINK,
                "transparent",
                5000,
            )
            logger.error(
                "❌ PermissionError occurred. User may need to run as administrator."
            )
        except Exception as e:
            # Catch any other errors during the file operations
            self.ok_button.configure(
                text=original_button_text, state="normal"
            )  # Reset button on error too
            utils.play_sound(
                "error.wav", logger, is_system_sound=False
            )  # Play custom error sound
            utils.show_status_message(
                self,
                logger,
                self.status_label,
                f"An unexpected error occurred: {str(e)}",
                constants.MONOKAI_ERROR_PINK,
                "transparent",
                3000,
            )
            logger.error(f"💥 An unexpected error occurred: {e}", exc_info=True)
        finally:
            self.restore_button.configure(state="normal") # Re-enable restore button

    def load_config(self):
        try:
            if os.path.exists(constants.CONFIG_FILE):
                with open(constants.CONFIG_FILE, "r") as f:
                    config = json.load(f)
                    self.destination_path_var.set(config.get("destination_path", ""))
                    self.english_menu_var.set(config.get("english_menu", False))
                    # Validate loaded path
                    if self.destination_path_var.get() and not self.validate_game_path(
                        self.destination_path_var.get()
                    ):
                        logger.warning(
                            f"⚠️ Loaded path '{self.destination_path_var.get()}' is no longer valid or accessible."
                        )
                        # self.destination_path_var.set("") # Optionally clear if invalid
        except Exception as e:
            logger.error(f"❌ Error loading config: {e}")

    def save_config(self):
        config = {
            "destination_path": self.destination_path_var.get(),
            "english_menu": self.english_menu_var.get(),
        }
        try:
            with open(constants.CONFIG_FILE, "w") as f:
                json.dump(config, f, indent=4)
            logger.info("💾 Configuration saved successfully.")
        except Exception as e:
            logger.error(f"❌ Error saving config: {e}")

    def _set_windows_taskbar_icon_style(self):
        if (
            os.name == "nt" and not self._style_set
        ):  # Only on Windows and if not already set
            from ctypes import windll

            GWL_EXSTYLE = -20
            WS_EX_APPWINDOW = 0x00040000
            WS_EX_TOOLWINDOW = 0x00000080
            try:
                hwnd = windll.user32.GetParent(self.winfo_id())
                if hwnd:  # Ensure hwnd is valid
                    style = windll.user32.GetWindowLongW(hwnd, GWL_EXSTYLE)
                    style = style & ~WS_EX_TOOLWINDOW  # Remove tool window style
                    style = style | WS_EX_APPWINDOW  # Add app window style
                    res = windll.user32.SetWindowLongW(hwnd, GWL_EXSTYLE, style)

                    # Force re-draw
                    self.withdraw()
                    self.after(10, self.deiconify)  # Use deiconify directly
                    self._style_set = True
                    logger.info("🎨 Windows taskbar style set successfully.")
            except Exception as e:
                logger.error(f"❌ Error setting Windows taskbar style: {e}")
                self.deiconify()  # Ensure window is shown even if style setting fails # pragma: no cover


if __name__ == "__main__":
    app = ModInstallerApp()  # Create an instance of the application
    if os.name == "nt":  # Only attempt on Windows
        app.after(
            10, app._set_windows_taskbar_icon_style
        )  # Call after a short delay to ensure window is ready
    app.mainloop()  # Start the Tkinter event loop
