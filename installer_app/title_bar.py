import customtkinter
import os
import logging
from PIL import Image
import utils
import constants

# Get logger instance
logger = logging.getLogger("ModInstallerApp") # Use the same logger as app.py

class CustomTitleBar(customtkinter.CTkFrame):
    def __init__(self, master, app_instance, **kwargs):
        # master is the main window (app_instance)
        super().__init__(master, height=35, fg_color=constants.MONOKAI_ELEMENT_BG, corner_radius=0, **kwargs)
        
        self.app_instance = app_instance # Keep a reference to the main app instance
        self._offset_x = 0 # For window dragging
        self._offset_y = 0 # For window dragging

        # --- Add Icon to Custom Title Bar ---
        try:
            # Use a .png or a small .ico for display. Large .ico might not render well.
            icon_display_path = utils.resource_path(os.path.join("installer_app", "assets", "RER-TH-mod-installer.ico")) # Or a PNG version
            if os.path.exists(icon_display_path):
                ctk_icon_image = customtkinter.CTkImage(
                    light_image=Image.open(icon_display_path),
                    dark_image=Image.open(icon_display_path),
                    size=(30, 30),
                )  # Adjust size as needed
                self.icon_label_titlebar = customtkinter.CTkLabel(
                    self, image=ctk_icon_image, text=""
                )
                self.icon_label_titlebar.pack(
                    side="left", padx=(5, 0), pady=5
                )  # Pack before title
        except Exception as e:
            logger.error(f"🎨❌ Error loading icon for title bar: {e}")

        # Bind events for dragging the window
        self.bind("<ButtonPress-1>", self._on_title_bar_press)
        self.bind("<B1-Motion>", self._on_title_bar_motion)

        # Close Button
        close_button = customtkinter.CTkButton(
            self,
            text="✕",  # Close symbol
            command=self.app_instance.on_closing, # Call method on main app instance
            width=35,
            height=35,
            fg_color="transparent",  # Transparent background
            text_color=constants.MONOKAI_TEXT_COLOR,
            hover_color=constants.MONOKAI_ERROR_COLOR,  # Reddish hover for close
            font=customtkinter.CTkFont(family=constants.DEFAULT_FONT_FAMILY, size=16, weight="bold"),
            corner_radius=0,
        )
        close_button.pack(side="right", padx=(0, 0))

        # Minimize Button
        minimize_button = customtkinter.CTkButton(
            self,
            text="—",  # Minimize symbol
            command=self.app_instance.minimize_window,  # Call method on main app instance
            width=35,
            height=35,
            fg_color="transparent",
            text_color=constants.MONOKAI_TEXT_COLOR,
            hover_color=constants.MONOKAI_ELEMENT_BORDER,  # Subtle hover
            font=customtkinter.CTkFont(family=constants.DEFAULT_FONT_FAMILY, size=16, weight="bold"),
            corner_radius=0,
        )
        minimize_button.pack(side="right", padx=(0, 0))

        # Application Title Label
        self.title_label = customtkinter.CTkLabel(  # Store as instance variable
            self,
            text=f"RER Thai Mod Installer {constants.APP_VERSION}",
            text_color=constants.MONOKAI_TEXT_COLOR,
            font=customtkinter.CTkFont(family=constants.DEFAULT_FONT_FAMILY, size=14, weight="bold"),
        )
        self.title_label.pack(side="left", padx=10, pady=5)
        # Also bind drag events to the title label
        self.title_label.bind("<ButtonPress-1>", self._on_title_bar_press)
        self.title_label.bind("<B1-Motion>", self._on_title_bar_motion)

    def _on_title_bar_press(self, event):
        self.app_instance._offset_x = event.x # Use app instance's offset variables
        self.app_instance._offset_y = event.y

    def _on_title_bar_motion(self, event):
        new_x = self.app_instance.winfo_x() + (event.x - self.app_instance._offset_x)
        new_y = self.app_instance.winfo_y() + (event.y - self.app_instance._offset_y)
        self.app_instance.geometry(f"+{new_x}+{new_y}")