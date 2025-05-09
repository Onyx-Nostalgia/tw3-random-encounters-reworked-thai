import os
import tkinter
import sys # Needed for resource_path

import constants  # Import constants directly, assuming it's in the same directory or Python path

if os.name == "nt":
    import winsound


_PROJECT_ROOT_DEV_UTILS = None # Cache for development project root

def get_project_root_or_bundle_dir_utils():
    """
    Returns the project root directory when running from source,
    or the bundle directory (_MEIPASS or executable's dir) when bundled.
    Assumes this file (utils.py) is in 'installer_app/' (or similar top-level app folder).
    """
    global _PROJECT_ROOT_DEV_UTILS
    if hasattr(sys, "_MEIPASS"):  # PyInstaller onefile bundle
        return sys._MEIPASS
    if getattr(sys, "frozen", False):  # PyInstaller onedir bundle
        return os.path.dirname(sys.executable)
    
    # Development mode
    if _PROJECT_ROOT_DEV_UTILS is None:
        # __file__ here is utils.py. If utils.py is in 'installer_app/',
        # project root is the parent directory of 'installer_app/'.
        _PROJECT_ROOT_DEV_UTILS = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    return _PROJECT_ROOT_DEV_UTILS

def resource_path(path_relative_to_project_root):
    """ Get absolute path to resource, works for dev and for PyInstaller. """
    base_dir = get_project_root_or_bundle_dir_utils()
    return os.path.join(base_dir, path_relative_to_project_root)

def validate_game_path(path_to_check):
    """
    Basic validation: check for 'mods', 'bin', and 'dlc' subfolders.
    This function is now in utils.py to be accessible early in app initialization.
    """
    if not path_to_check or not os.path.isdir(path_to_check):
        return False

    has_folders = ["mods", "bin", "dlc"]
    for folder in has_folders:
        if not os.path.isdir(os.path.join(path_to_check, folder)):
            return False
    return True  # All required folders exist

def play_sound(sound_identifier: str, logger, block=False, is_system_sound=False):
    """
    Plays a sound.
    If is_system_sound is True (Windows only), sound_identifier is a system sound alias (e.g., 'SystemAsterisk').
    Otherwise, sound_identifier is a filename in 'assets/sounds/'.
    The 'block' parameter determines if playback is synchronous (True) or asynchronous (False).
    For system sounds, playback is generally asynchronous.
    """
    if os.name == 'nt':  # winsound is Windows-specific
        if is_system_sound:
            # Play a system sound alias (e.g., 'SystemAsterisk')
            try:
                # System sounds are typically played asynchronously.
                # The 'block' parameter is not strictly applied here to maintain simple async behavior for system alerts.
                winsound.PlaySound(sound_identifier, winsound.SND_ALIAS | winsound.SND_ASYNC)
                logger.debug(f"🔊 Played system sound: {sound_identifier}")
            except Exception as e:
                logger.error(f"🔊❌ Error playing system sound '{sound_identifier}': {e}")
        else:
            # Play a custom sound file from 'assets/sounds/'
            try:
                # Path relative to project root: "installer_app/assets/sounds/sound.wav"
                sound_file_path = resource_path(os.path.join("installer_app", "assets", "sounds", sound_identifier))

                if os.path.exists(sound_file_path):
                    flags = winsound.SND_FILENAME
                    if not block:  # If block is False, play asynchronously
                        flags |= winsound.SND_ASYNC
                    # If block is True, play synchronously (SND_FILENAME alone is synchronous)
                    
                    winsound.PlaySound(sound_file_path, flags)
                    logger.debug(f"🔊 Played custom sound file: {sound_file_path}")
                else:
                    logger.error(f"🔊❌ Custom sound file not found: {sound_file_path}")
            except Exception as e:
                logger.error(f"🔊❌ Error playing custom sound file '{sound_identifier}': {e}")
    else:  # Not on Windows
        if is_system_sound:
            logger.warning("🔊⚠️ System sounds are only supported on Windows.")
        else:
            # Custom sound file playback also relies on winsound here
            logger.warning(f"🔊⚠️ Custom sound file playback via winsound is only supported on Windows. Sound '{sound_identifier}' from file not played.")

def hex_to_rgb(hex_color_str):
    """Helper to convert #RRGGBB to (r, g, b) tuple."""
    if not isinstance(hex_color_str, str):
        return None
    if hex_color_str == "transparent":
        # For fading purposes, treat transparent as the main background color
        return hex_to_rgb(constants.MONOKAI_MAIN_BG)
    hex_color_str = hex_color_str.lstrip("#")
    if len(hex_color_str) == 6:
        try:
            return tuple(int(hex_color_str[i : i + 2], 16) for i in (0, 2, 4))
        except ValueError:
            return None  # Invalid hex
    return None


def rgb_to_hex(rgb_tuple):
    """Helper to convert (r, g, b) to #RRGGBB string."""
    try:
        return f"#{rgb_tuple[0]:02x}{rgb_tuple[1]:02x}{rgb_tuple[2]:02x}"
    except (IndexError, TypeError):
        return None  # Invalid rgb tuple


def animate_widget_color(
    app_instance,
    logger,
    widget,
    target_fg_color_hex,
    target_text_color_hex,
    target_text,
    steps,
    callback=None,
):
    """Animates fg_color and text_color of a widget."""
    logger.debug(f"--- Animating widget: {widget} ---")
    logger.debug(f"  Target FG: {target_fg_color_hex}")
    logger.debug(f"  Target Text Color: {target_text_color_hex}")
    logger.debug(f"  Target Text: {target_text}")

    try:
        current_fg_color_hex = (
            widget.cget("fg_color") if target_fg_color_hex is not None else None
        )
    except tkinter.TclError:
        current_fg_color_hex = None

    try:
        current_text_color_hex = (
            widget.cget("text_color") if target_text_color_hex is not None else None
        )
    except tkinter.TclError:
        current_text_color_hex = None

    logger.debug(f"  Current FG: {current_fg_color_hex}")
    logger.debug(f"  Current Text Color: {current_text_color_hex}")

    start_fg_rgb = (
        hex_to_rgb(current_fg_color_hex)
        if current_fg_color_hex and target_fg_color_hex
        else None
    )
    end_fg_rgb = hex_to_rgb(target_fg_color_hex) if target_fg_color_hex else None
    start_text_rgb = (
        hex_to_rgb(current_text_color_hex)
        if current_text_color_hex and target_text_color_hex
        else None
    )
    end_text_rgb = hex_to_rgb(target_text_color_hex) if target_text_color_hex else None

    if target_text is not None and hasattr(widget, "configure"):
        try:
            widget.configure(text=target_text)
        except tkinter.TclError:
            pass

    def _animate_step(current_step):
        if current_step <= steps:
            progress = current_step / float(steps)
            new_config = {}

            if start_fg_rgb and end_fg_rgb:
                new_fg_r = int(
                    start_fg_rgb[0] + (end_fg_rgb[0] - start_fg_rgb[0]) * progress
                )
                new_fg_g = int(
                    start_fg_rgb[1] + (end_fg_rgb[1] - start_fg_rgb[1]) * progress
                )
                new_fg_b = int(
                    start_fg_rgb[2] + (end_fg_rgb[2] - start_fg_rgb[2]) * progress
                )
                new_config["fg_color"] = rgb_to_hex((new_fg_r, new_fg_g, new_fg_b))

            if start_text_rgb and end_text_rgb:
                new_text_r = int(
                    start_text_rgb[0] + (end_text_rgb[0] - start_text_rgb[0]) * progress
                )
                new_text_g = int(
                    start_text_rgb[1] + (end_text_rgb[1] - start_text_rgb[1]) * progress
                )
                new_text_b = int(
                    start_text_rgb[2] + (end_text_rgb[2] - start_text_rgb[2]) * progress
                )
                new_config["text_color"] = rgb_to_hex(
                    (new_text_r, new_text_g, new_text_b)
                )

            logger.debug(f"  Step {current_step}/{steps}, New Config: {new_config}")
            if new_config and hasattr(widget, "configure"):
                try:
                    widget.configure(**new_config)
                except tkinter.TclError as e:
                    logger.debug(
                        f"⚠️ Could not configure widget {widget} with {new_config}: {e}"
                    )
                    pass

            app_instance.after(30, lambda: _animate_step(current_step + 1))
        elif callback:
            logger.debug(f"--- Animation finished for widget: {widget} ---")
            callback()

    _animate_step(1)


def _animate_status_bg_fade_in_recursive(
    app_instance,
    status_label,
    message,
    target_fg_color,
    current_animation_bg_color,
    animation_step_remaining,
    max_animation_steps,
    hold_duration_ms,
    fade_out_callback,
):
    if animation_step_remaining >= 0:
        status_label.configure(text=message)
        progress_factor = (
            (max_animation_steps - animation_step_remaining)
            / float(max_animation_steps)
            if max_animation_steps > 0
            else 1.0
        )
        start_rgb = hex_to_rgb(current_animation_bg_color)
        end_rgb = hex_to_rgb(target_fg_color)

        if not start_rgb or not end_rgb:
            status_label.configure(fg_color=target_fg_color)
            if animation_step_remaining == 0:
                app_instance.after(hold_duration_ms, fade_out_callback)
            return

        new_r = int(start_rgb[0] + (end_rgb[0] - start_rgb[0]) * progress_factor)
        new_g = int(start_rgb[1] + (end_rgb[1] - start_rgb[1]) * progress_factor)
        new_b = int(start_rgb[2] + (end_rgb[2] - start_rgb[2]) * progress_factor)
        interpolated_fg_hex = rgb_to_hex(
            (max(0, min(255, new_r)), max(0, min(255, new_g)), max(0, min(255, new_b)))
        )
        status_label.configure(fg_color=interpolated_fg_hex)
        app_instance.after(
            30,
            lambda: _animate_status_bg_fade_in_recursive(
                app_instance,
                status_label,
                message,
                target_fg_color,
                current_animation_bg_color,
                animation_step_remaining - 1,
                max_animation_steps,
                hold_duration_ms,
                fade_out_callback,
            ),
        )
    else:
        status_label.configure(fg_color=target_fg_color)
        app_instance.after(hold_duration_ms, fade_out_callback)


def clear_status_box_immediately(status_label):
    status_label.configure(
        text="", fg_color="transparent", text_color=constants.MONOKAI_TEXT_COLOR
    )


def fade_out_status_box(app_instance, status_label, step=15):
    if status_label.cget("text") == "":
        clear_status_box_immediately(status_label)
        return
    target_bg_rgb = hex_to_rgb(constants.MONOKAI_MAIN_BG)
    if not target_bg_rgb:
        clear_status_box_immediately(status_label)
        return
    current_text_color_str = status_label.cget("text_color")
    current_fg_color_str = status_label.cget("fg_color")
    current_text_rgb = hex_to_rgb(current_text_color_str)
    if not current_text_rgb:
        clear_status_box_immediately(status_label)
        return
    if step > 0:
        new_r_text = int(
            current_text_rgb[0] + (target_bg_rgb[0] - current_text_rgb[0]) / step
        )
        new_g_text = int(
            current_text_rgb[1] + (target_bg_rgb[1] - current_text_rgb[1]) / step
        )
        new_b_text = int(
            current_text_rgb[2] + (target_bg_rgb[2] - current_text_rgb[2]) / step
        )
        new_text_color_hex = rgb_to_hex((new_r_text, new_g_text, new_b_text))
        new_fg_color_hex = (
            "transparent"
            if current_fg_color_str == "transparent"
            else current_fg_color_str
        )
        if current_fg_color_str != "transparent":
            current_fg_rgb = hex_to_rgb(current_fg_color_str)
            if current_fg_rgb:
                new_r_fg = int(
                    current_fg_rgb[0] + (target_bg_rgb[0] - current_fg_rgb[0]) / step
                )
                new_g_fg = int(
                    current_fg_rgb[1] + (target_bg_rgb[1] - current_fg_rgb[1]) / step
                )
                new_b_fg = int(
                    current_fg_rgb[2] + (target_bg_rgb[2] - current_fg_rgb[2]) / step
                )
                new_fg_color_hex = rgb_to_hex((new_r_fg, new_g_fg, new_b_fg))
        status_label.configure(text_color=new_text_color_hex, fg_color=new_fg_color_hex)
        app_instance.after(
            50, lambda: fade_out_status_box(app_instance, status_label, step - 1)
        )
    else:
        clear_status_box_immediately(status_label)


def show_status_message(
    app_instance,
    logger,
    status_label,
    message: str,
    text_color: str,
    fg_color: str,
    duration_ms: int,
    fade_animation_steps: int = 15,
):
    status_label.configure(text=message, text_color=text_color)
    if fg_color == "transparent":
        status_label.configure(fg_color="transparent")
        status_label.lift()
        app_instance.after(
            duration_ms,
            lambda: fade_out_status_box(
                app_instance, status_label, fade_animation_steps
            ),
        )
    else:
        fade_out_cb = lambda: fade_out_status_box(
            app_instance, status_label, fade_animation_steps
        )
        _animate_status_bg_fade_in_recursive(
            app_instance,
            status_label,
            message,
            fg_color,
            constants.MONOKAI_MAIN_BG,
            fade_animation_steps,
            fade_animation_steps,
            duration_ms,
            fade_out_cb,
        )
