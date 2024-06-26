// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
use mouse_rs::{types::keys::Keys, Mouse};
use tauri::{CustomMenuItem, Manager};

#[tauri::command]
fn debug() -> bool {
    #[cfg(debug_assertions)]
    {
        true
    }
    #[cfg(not(debug_assertions))]
    {
        false
    }
}

#[tauri::command]
fn move_mouse(x: i32, y: i32) {
    let mouse = Mouse::new();
    mouse.move_to(x, y).expect("Unable to move mouse");
}

#[tauri::command]
fn left_click(x: i32, y: i32) {
    let mouse = Mouse::new();
    if x != -1 {
        mouse.move_to(x, y).expect("Unable to move mouse");
    }
    mouse.click(&Keys::LEFT).expect("Unable to click button");
}

#[tauri::command]
fn right_click(x: i32, y: i32) {
    let mouse = Mouse::new();
    if x != -1 {
        mouse.move_to(x, y).expect("Unable to move mouse");
    }
    mouse.click(&Keys::RIGHT).expect("Unable to click button");
}

fn main() {
    let mut open = CustomMenuItem::new("open".to_string(), "Open");
    open = open.accelerator("o".to_string());
    let mut quit = CustomMenuItem::new("quit".to_string(), "Quit");
    quit = quit.accelerator("q".to_string());
    let tray_menu = tauri::SystemTrayMenu::new()
        .add_item(open)
        .add_native_item(tauri::SystemTrayMenuItem::Separator)
        .add_item(quit);
    let system_tray = tauri::SystemTray::new().with_menu(tray_menu);
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            debug,
            move_mouse,
            left_click,
            right_click
        ])
        .on_window_event(|event| {
            if let tauri::WindowEvent::CloseRequested { api, .. } = event.event() {
                event.window().hide().unwrap();
                api.prevent_close();
            }
        })
        .system_tray(system_tray)
        .on_system_tray_event(|app, event| {
            if let tauri::SystemTrayEvent::MenuItemClick { id, .. } = event {
                match id.as_str() {
                    "open" => {
                        let window = Manager::get_window(app, "main").unwrap();
                        window.show().unwrap();
                        window.set_focus().unwrap();
                    }
                    "quit" => {
                        app.exit(0);
                    }
                    _ => {}
                }
            }
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
