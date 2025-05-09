import customtkinter
import tkinter
import os  # Needed for path operations
import logging  # For logging
import json  # For handling config file
import constants  # Assuming constants.py is in the same directory
import utils  # Assuming utils.py is in the same directory
from title_bar import CustomTitleBar  # Import the new TitleBar class
from installer_logic import ModInstallerLogic  # Import the new Logic class

# --- Logger Setup ---
logger = logging.getLogger("ModInstallerApp")
logger.setLevel(
    logging.INFO
)  # Set to DEBUG to catch all levels, can be changed to INFO for production

ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)  # Or INFO for less verbose output

formatter = logging.Formatter(
    "%(asctime)s - [%(levelname)-7s] - %(message)s", datefmt="%Y-%m-%d %H:%M:%S"
)
ch.setFormatter(formatter)

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
        self.geometry("600x360")  # Adjusted height

        customtkinter.set_appearance_mode(
            "dark"
        )  # Ensure dark mode is globally set for customtkinter

        # --- Set Application Icon ---
        try:
            # Path relative to project root: "installer_app/assets/RER-TH-mod-installer.ico"
            icon_path = utils.resource_path(
                os.path.join("installer_app", "assets", "RER-TH-mod-installer.ico")
            )
            self.iconbitmap(icon_path)
            self.update_idletasks()
        except Exception as e:
            logger.error(f"🎨❌ Error setting application icon: {e}")

        self._offset_x = 0
        self._offset_y = 0

        # Create custom title bar first
        self._create_custom_title_bar()

        # Remove default OS title bar AFTER creating custom one
        self.overrideredirect(True)

        # --- Application Variables ---
        self.destination_path_var = (
            tkinter.StringVar()
        )  # Variable to store the selected destination path
        self.english_menu_var = (
            tkinter.BooleanVar()
        )  # Variable to store the state of the English menu checkbox

        # --- UI Elements ---
        # Create a main frame for content with padding
        self.main_frame = customtkinter.CTkFrame(self, fg_color="transparent")
        self.main_frame.pack(
            pady=(0, 20), padx=25, fill="both", expand=True
        )

        # --- Destination Path Selection ---
        self.path_label = customtkinter.CTkLabel(
            self.main_frame,
            text="Game Folder:",
            text_color=constants.MONOKAI_TEXT_COLOR,
            font=customtkinter.CTkFont(
                family=constants.DEFAULT_FONT_FAMILY, size=16)
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
                family=constants.DEFAULT_FONT_FAMILY, size=14),
            height=35,
        )
        self.path_entry.pack(side="left", fill="x", expand=True, padx=(0, 10))

        self.browse_button = customtkinter.CTkButton(
            self.path_controls_frame,
            text="Browse",
            fg_color=constants.MONOKAI_ELEMENT_BG,
            text_color=constants.MONOKAI_TEXT_COLOR,
            hover_color=constants.MONOKAI_ACCENT_YELLOW,  # Highlight with yellow on hover
            border_color=constants.MONOKAI_ELEMENT_BORDER,
            border_width=1,
            font=customtkinter.CTkFont(
                family=constants.DEFAULT_FONT_FAMILY, size=14, weight="bold"),
            height=35,
        )
        self.browse_button.pack(side="left")

        # --- English Menu Checkbox ---
        self.english_menu_checkbox = customtkinter.CTkCheckBox(
            self.main_frame,
            text="English Menu Version",
            variable=self.english_menu_var,
            text_color=constants.MONOKAI_TEXT_COLOR,
            font=customtkinter.CTkFont(
                family=constants.DEFAULT_FONT_FAMILY, size=16),
            fg_color=constants.MONOKAI_ACCENT_YELLOW,  # Color of the checkbox itself when checked
            hover_color=constants.MONOKAI_ACCENT_YELLOW_HOVER,  # Hover color for the checkbox
            checkmark_color=constants.MONOKAI_MAIN_BG,  # Color of the check mark symbol (dark on yellow)
        )
        self.english_menu_checkbox.pack(pady=15, anchor="w")

        # --- OK Button ---
        self.ok_button = customtkinter.CTkButton(
            self.main_frame,
            text="Install",
            fg_color=constants.MONOKAI_ACCENT_YELLOW,  # Prominent yellow for the main action button
            text_color=constants.MONOKAI_MAIN_BG,  # Dark text for contrast on yellow button
            hover_color=constants.MONOKAI_ACCENT_YELLOW_HOVER,  # Lighter yellow for hover
            font=customtkinter.CTkFont(
                family=constants.DEFAULT_FONT_FAMILY, size=16, weight="bold"),
            height=35,
        )
        self.ok_button.pack(pady=20, fill="x")

        # --- Uninstall Button (formerly Restore Button) ---
        self.restore_button = customtkinter.CTkButton(
            self.main_frame,
            text="Uninstall",  # Changed text
            fg_color=constants.MONOKAI_ELEMENT_BG,
            text_color=constants.MONOKAI_TEXT_COLOR,
            hover_color=constants.MONOKAI_ACCENT_YELLOW_HOVER,
            border_color=constants.MONOKAI_ELEMENT_BORDER,
            border_width=1,
            font=customtkinter.CTkFont(
                family=constants.DEFAULT_FONT_FAMILY, size=16, weight="bold"
            ),
            height=35,
        )
        self.restore_button.pack(pady=(0, 10), fill="x")

        # --- Status Label ---
        self.status_label = customtkinter.CTkLabel(
            self.main_frame,
            text="",  # Initially empty
            font=customtkinter.CTkFont(
                family=constants.DEFAULT_FONT_FAMILY, size=16, weight="bold"),
        )
        self.status_label.configure(width=250)
        self.status_label.pack(pady=10, ipady=8)

        # Load config on startup
        self.load_config()
        self.protocol("WM_DELETE_WINDOW", self.on_closing)

        # --- Initialize Logic Handler ---
        self.logic_handler = ModInstallerLogic(
            self,
            self.destination_path_var,
            self.english_menu_var,
            self.status_label,
            self.ok_button,
            self.restore_button,  # This is now the Uninstall button
        )
        # Set commands for buttons using the logic handler
        self.browse_button.configure(
            command=self.logic_handler.select_destination_folder
        )
        self.path_entry.bind(
            "<Button-1>", lambda event: self.logic_handler.select_destination_folder()
        )
        self.ok_button.configure(command=self.logic_handler.start_process)
        self.restore_button.configure(
            command=self.logic_handler.confirm_uninstall
        )  # Changed command

    def _create_custom_title_bar(self):
        self.title_bar_frame = CustomTitleBar(master=self, app_instance=self)
        self.title_bar_frame.pack(side="top", fill="x")
        self.title_label = self.title_bar_frame.title_label

    def minimize_window(self):
        if os.name == "nt":
            try:
                from ctypes import windll

                hwnd_to_minimize = windll.user32.GetParent(self.winfo_id())
                if hwnd_to_minimize:
                    SW_MINIMIZE = 6
                    windll.user32.ShowWindow(hwnd_to_minimize, SW_MINIMIZE)
                else:
                    logger.error(
                        "❌ Minimize Error: Could not get parent HWND via GetParent(self.winfo_id()). Cannot use Windows API to minimize."
                    )
            except Exception as e:
                logger.error(f"❌ Error during Windows API minimize attempt: {e}")
        else:
            super().iconify()

    # validate_game_path is now handled by utils.py
    # This method in app.py is removed to avoid duplication.

    def on_closing(self):
        try:
            self.save_config()
            if hasattr(self, "title_bar_frame") and self.title_bar_frame.winfo_exists():
                self.title_bar_frame.unbind("<ButtonPress-1>")
                self.title_bar_frame.unbind("<B1-Motion>")
                if (
                    hasattr(self.title_bar_frame, "title_label")
                    and self.title_bar_frame.title_label.winfo_exists()
                ):
                    self.title_bar_frame.title_label.unbind("<ButtonPress-1>")
                    self.title_bar_frame.title_label.unbind("<B1-Motion>")
        except Exception as e:
            logger.error(f"🧹❌ Error during pre-closing cleanup: {e}")
        finally:
            self.destroy()

    def _ui_set_uninstalling_state(self):  # Renamed
        """Sets UI to 'Uninstalling...' state."""
        original_install_button_text = self.ok_button.cget("text")
        original_uninstall_button_text = self.restore_button.cget(
            "text"
        )  # restore_button is now Uninstall button
        self.ok_button.configure(state="disabled")
        self.restore_button.configure(
            text="Uninstalling...",  # Changed text
            state="disabled", # type: ignore
            text_color_disabled=constants.MONOKAI_MAIN_BG,
        )
        self.status_label.configure(text="")
        self.update_idletasks()
        return {
            "install_text": original_install_button_text,
            "uninstall_text": original_uninstall_button_text,  # Renamed key
        } # type: ignore

    def _ui_handle_uninstall_completion(  # Renamed
        self,
        original_install_text, # type: ignore
        original_uninstall_text,  # Renamed
        success,
        message_text,
        message_color,
        duration_ms=None,
    ):
        """Handles UI updates after uninstall attempt."""
        if duration_ms is None:
            duration_ms = 3000 if success else 4000

        if success:
            utils.play_sound("done.wav", logger, is_system_sound=False)
        else:
            utils.play_sound("error.wav", logger, is_system_sound=False)

        utils.show_status_message(
            self,
            logger,
            self.status_label,
            message_text,
            message_color,
            "transparent",
            duration_ms,
        )
        self.ok_button.configure(text=original_install_text, state="normal")
        self.restore_button.configure( # type: ignore
            text=original_uninstall_text, state="normal"
        )  # Use new original text

    def _ui_set_installing_state(self):
        original_button_text = self.ok_button.cget("text")
        self.ok_button.configure(
            text="Installing...",
            state="disabled",
            text_color_disabled=constants.MONOKAI_MAIN_BG, # type: ignore
        )
        self.status_label.configure(text="")
        self.update_idletasks()
        self.restore_button.configure(state="disabled")
        return original_button_text

    def _ui_handle_install_success(self, original_button_text):
        self.ok_button.configure(
            text="✓ Done!", text_color_disabled=constants.MONOKAI_TEXT_COLOR # type: ignore
        )
        utils.animate_widget_color(
            self,
            logger,
            self.ok_button,
            constants.MONOKAI_SUCCESS_COLOR,
            constants.MONOKAI_TEXT_COLOR,
            "✓ Done!",
            15,
            callback=lambda: utils.play_sound(
                "done.wav", logger, is_system_sound=False
            ),
        )
        utils.animate_widget_color(
            self,
            logger,
            self.title_bar_frame,
            constants.MONOKAI_SUCCESS_COLOR,
            None,
            None,
            15,
        )
        utils.animate_widget_color(
            self,
            logger,
            self.title_bar_frame.title_label,
            None,
            constants.MONOKAI_MAIN_BG,
            None,
            15,
        )

        def return_to_normal_state_setup():
            self.ok_button.configure(
                text=original_button_text, text_color_disabled=constants.MONOKAI_MAIN_BG # type: ignore
            )
            utils.animate_widget_color(
                self,
                logger,
                self.ok_button,
                constants.MONOKAI_ACCENT_YELLOW,
                constants.MONOKAI_MAIN_BG,
                original_button_text,
                15,
                callback=lambda: self.ok_button.configure(state="normal"), # type: ignore
            )
            utils.animate_widget_color(
                self,
                logger,
                self.title_bar_frame,
                constants.MONOKAI_ELEMENT_BG,
                None,
                None,
                15,
            )
            utils.animate_widget_color(
                self,
                logger,
                self.title_bar_frame.title_label,
                None,
                constants.MONOKAI_TEXT_COLOR,
                None,
                15,
                callback=lambda: self.restore_button.configure(state="normal"), # type: ignore
            )

        animation_duration_ms = 15 * 30
        hold_duration_ms = 1500
        self.after(
            animation_duration_ms + hold_duration_ms, return_to_normal_state_setup
        )

    def _ui_handle_install_error(
        self,
        original_button_text,
        display_message,
        log_message,
        exception_obj=None,
        exc_info=False,
    ):
        self.ok_button.configure(text=original_button_text, state="normal")
        self.restore_button.configure(state="normal")
        utils.play_sound("error.wav", logger, is_system_sound=False)
        utils.show_status_message(
            self,
            logger,
            self.status_label,
            display_message,
            constants.MONOKAI_ERROR_COLOR,
            "transparent",
            5000,
        )
        if exc_info and exception_obj:
            logger.error(log_message, exc_info=True)
        else:
            logger.error(log_message)

    def _get_config_file_path(self, use_default=False):
        """
        Returns the absolute path to the config file.
        If use_default is True, returns path to the default config file.
        """
        filename = (
            constants.DEFAULT_CONFIG_FILE if use_default else constants.CONFIG_FILE
        )
        return utils.resource_path(os.path.join("installer_app", filename))

    def load_config(self):
        """Loads configuration from config.json."""
        default_config_path = self._get_config_file_path(use_default=True)
        user_config_path = self._get_config_file_path(use_default=False)

        # Start with hardcoded in-app defaults as a last resort
        current_dest_path = ""
        current_english_menu = False

        # 1. Try to load from config.default.json
        try:
            if os.path.exists(default_config_path):
                with open(default_config_path, "r") as f:
                    default_config = json.load(f)
                    current_dest_path = default_config.get(
                        "destination_path", current_dest_path # Use current_dest_path as fallback
                    )
                    current_english_menu = default_config.get(
                        "english_menu", current_english_menu
                    )
                    logger.info(
                        f"💾 Default config loaded from '{default_config_path}'."
                    )
        except Exception as e:
            logger.error(
                f"❌ Error loading default config '{default_config_path}': {e}"
            )

        # 2. Try to load from user's config.json (will override defaults if keys exist)
        try:
            if os.path.exists(user_config_path):
                with open(user_config_path, "r") as f:
                    user_config = json.load(f)
                    current_dest_path = user_config.get(
                        "destination_path", current_dest_path # Use current_dest_path as fallback
                    )
                    current_english_menu = user_config.get(
                        "english_menu", current_english_menu
                    )
                    logger.info(f"💾 User config loaded from '{user_config_path}'.")
        except Exception as e:
            # Only log error if the file exists but is malformed, not if it simply doesn't exist
            if os.path.exists(user_config_path):
                logger.error(f"❌ Error loading user config '{user_config_path}': {e}")

        self.destination_path_var.set(current_dest_path)
        self.english_menu_var.set(current_english_menu)

        if current_dest_path and not utils.validate_game_path(current_dest_path): # Call validate_game_path from utils
            logger.warning(
                f"⚠️ Loaded path '{current_dest_path}' is no longer valid or accessible."
            )

    def save_config(self):
        """Saves current configuration to config.json."""
        config = {
            "destination_path": self.destination_path_var.get(),
            "english_menu": self.english_menu_var.get(),
        }
        config_path = self._get_config_file_path(
            use_default=False
        )  # Always save to user's config.json
        try:
            with open(config_path, "w") as f:
                json.dump(config, f, indent=4)
            logger.info("💾 Configuration saved successfully.")
        except Exception as e:
            logger.error(f"❌ Error saving config: {e}")

    def _set_windows_taskbar_icon_style(self):
        """Sets the window style to appear correctly in the Windows taskbar."""
        if os.name == "nt" and not self._style_set:
            from ctypes import windll

            GWL_EXSTYLE = -20
            WS_EX_APPWINDOW = 0x00040000
            WS_EX_TOOLWINDOW = 0x00000080
            try:
                GA_ROOT = 2  # Define GA_ROOT constant
                hwnd = windll.user32.GetAncestor(self.winfo_id(), GA_ROOT)  # Get the top-level window handle
                if hwnd:
                    style = windll.user32.GetWindowLongW(hwnd, GWL_EXSTYLE)
                    style = (style & ~WS_EX_TOOLWINDOW) | WS_EX_APPWINDOW
                    windll.user32.SetWindowLongW(hwnd, GWL_EXSTYLE, style)
                    windll.user32.SetWindowPos(hwnd, 0, 0, 0, 0, 0, 0x0001 | 0x0002 | 0x0020)  # Apply changes
                    self.withdraw()
                    self.after(10, self.deiconify)
                    self._style_set = True
                    logger.info("🎨 Windows taskbar style set successfully.")
            except Exception as e:
                logger.error(f"❌ Error setting Windows taskbar style: {e}")
                self.deiconify()


if __name__ == "__main__":
    app = ModInstallerApp()
    if os.name == "nt":
        app.after(10, app._set_windows_taskbar_icon_style)
    app.mainloop()
