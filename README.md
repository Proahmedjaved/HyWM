# HyWM - Hyprland Workspace Manager

HyWM is a command-line tool for creating, managing, and launching application layouts in the Hyprland window manager. Users can define "sessions" which consist of specific applications assigned to particular workspaces. The script then allows for easy launching of all applications in a session, automatically placing them on their designated workspaces.

## Features

*   Create and manage custom sessions.
*   Launch all applications in a session in parallel.
*   Interactive fzf menu for app selection.
*   Colored output for better readability.

## Installation

1.  Make sure you have the following dependencies installed:
    *   `hyprland`
    *   `fzf`
    *   `parallel` (from GNU Parallel)
2.  Clone this repository:
    ```bash
    git clone https://github.com/your-username/HyWM.git
    ```
3.  Make the script executable:
    ```bash
    chmod +x HyWM/start_session.sh
    ```

## Usage

*   **Setup a new session:**
    ```bash
    ./start_session.sh setup [session_name]
    ```
*   **Launch a session:**
    ```bash
    ./start_session.sh launch [session_name]
    ```
*   **List all sessions:**
    ```bash
    ./start_session.sh list
    ```
*   **Delete a session:**
    ```bash
    ./start_session.sh delete [session_name]
    ```

## Contributing

Contributions are welcome! Please see the [CONTRIBUTING.md](CONTRIBUTING.md) file for details.

## Author

*   **Ahmed Javed** - [ahmedjaved701@gmail.com](mailto:ahmedjaved701@gmail.com)
