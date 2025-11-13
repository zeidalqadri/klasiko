#!/usr/bin/env python3
"""
Klasiko GUI - Cross-platform graphical interface for Klasiko PDF Converter

A tkinter-based GUI that works on Windows, macOS, and Linux.
Provides an easy-to-use interface for converting Markdown to PDF with
theme selection, logo branding, and metadata options.

Usage:
    python klasiko-gui.py
    or double-click the file (if Python is properly configured)
"""

import tkinter as tk
from tkinter import ttk, filedialog, messagebox, scrolledtext
import os
import sys
import subprocess
import threading
from pathlib import Path

# Import klasiko if available (for embedded version)
try:
    import klasiko
    KLASIKO_EMBEDDED = True
except ImportError:
    KLASIKO_EMBEDDED = False


class KlasikoGUI:
    """Main GUI application for Klasiko PDF Converter"""

    def __init__(self, root):
        self.root = root
        self.root.title("Klasiko PDF Converter")
        self.root.geometry("800x900")

        # Set icon if available
        self.set_icon()

        # Variables
        self.input_file = tk.StringVar()
        self.output_file = tk.StringVar()
        self.theme = tk.StringVar(value="warm")
        self.toc_enabled = tk.BooleanVar(value=False)
        self.logo_file = tk.StringVar()
        self.author = tk.StringVar()
        self.subject = tk.StringVar()
        self.keywords = tk.StringVar()

        # Logo placement options
        self.logo_placements = []
        self.placement_vars = {}

        # Create UI
        self.create_widgets()

    def set_icon(self):
        """Set window icon if available"""
        try:
            if sys.platform == 'win32':
                icon_path = Path('packaging/windows/klasiko.ico')
                if icon_path.exists():
                    self.root.iconbitmap(str(icon_path))
            elif sys.platform == 'darwin':
                # macOS doesn't support .ico, would need .icns
                pass
        except:
            pass  # Icon not critical, skip if fails

    def create_widgets(self):
        """Create all GUI widgets"""
        # Main container with padding
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))

        # Configure grid weights for resizing
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)

        row = 0

        # Title
        title_label = ttk.Label(main_frame, text="Klasiko PDF Converter",
                               font=('Helvetica', 16, 'bold'))
        title_label.grid(row=row, column=0, columnspan=3, pady=(0, 20))
        row += 1

        # Input file section
        ttk.Label(main_frame, text="Input Markdown File:",
                 font=('Helvetica', 10, 'bold')).grid(row=row, column=0, sticky=tk.W, pady=(0, 5))
        row += 1

        ttk.Entry(main_frame, textvariable=self.input_file, width=50).grid(
            row=row, column=0, columnspan=2, sticky=(tk.W, tk.E), padx=(0, 5))
        ttk.Button(main_frame, text="Browse...", command=self.browse_input).grid(
            row=row, column=2)
        row += 1

        # Output file section
        ttk.Label(main_frame, text="Output PDF File (optional):",
                 font=('Helvetica', 10, 'bold')).grid(row=row, column=0, sticky=tk.W, pady=(10, 5))
        row += 1

        ttk.Entry(main_frame, textvariable=self.output_file, width=50).grid(
            row=row, column=0, columnspan=2, sticky=(tk.W, tk.E), padx=(0, 5))
        ttk.Button(main_frame, text="Browse...", command=self.browse_output).grid(
            row=row, column=2)
        row += 1

        # Theme selection
        ttk.Label(main_frame, text="Visual Theme:",
                 font=('Helvetica', 10, 'bold')).grid(row=row, column=0, sticky=tk.W, pady=(10, 5))
        row += 1

        theme_frame = ttk.Frame(main_frame)
        theme_frame.grid(row=row, column=0, columnspan=3, sticky=tk.W, pady=(0, 10))

        themes = [
            ("Default (Clean & Professional)", "default"),
            ("Warm (Vintage Amber - Default)", "warm"),
            ("Rustic (Earth Tones)", "rustic")
        ]

        for text, value in themes:
            ttk.Radiobutton(theme_frame, text=text, variable=self.theme,
                           value=value).pack(anchor=tk.W)
        row += 1

        # Table of Contents
        ttk.Checkbutton(main_frame, text="Generate Table of Contents",
                       variable=self.toc_enabled).grid(row=row, column=0, columnspan=3,
                                                       sticky=tk.W, pady=(0, 10))
        row += 1

        # Logo section
        ttk.Label(main_frame, text="Logo Branding (optional):",
                 font=('Helvetica', 10, 'bold')).grid(row=row, column=0, sticky=tk.W, pady=(10, 5))
        row += 1

        ttk.Entry(main_frame, textvariable=self.logo_file, width=50).grid(
            row=row, column=0, columnspan=2, sticky=(tk.W, tk.E), padx=(0, 5))
        ttk.Button(main_frame, text="Browse...", command=self.browse_logo).grid(
            row=row, column=2)
        row += 1

        # Logo placement options
        ttk.Label(main_frame, text="Logo Placement Positions:",
                 font=('Helvetica', 9)).grid(row=row, column=0, columnspan=3,
                                            sticky=tk.W, pady=(10, 5))
        row += 1

        placement_frame = ttk.LabelFrame(main_frame, text="Select placement and size",
                                         padding="10")
        placement_frame.grid(row=row, column=0, columnspan=3, sticky=(tk.W, tk.E),
                            pady=(0, 10))

        placements = [
            ("Title Page", "title"),
            ("Header", "header"),
            ("Footer", "footer"),
            ("Both Header & Footer", "both"),
            ("Watermark", "watermark"),
            ("All Positions", "all")
        ]

        sizes = ["small", "medium", "large"]

        placement_grid_row = 0
        for pos_text, pos_value in placements:
            ttk.Label(placement_frame, text=pos_text + ":").grid(
                row=placement_grid_row, column=0, sticky=tk.W, padx=(0, 10))

            size_var = tk.StringVar(value="")
            self.placement_vars[pos_value] = size_var

            size_frame = ttk.Frame(placement_frame)
            size_frame.grid(row=placement_grid_row, column=1, sticky=tk.W)

            for size in sizes:
                ttk.Radiobutton(size_frame, text=size.capitalize(),
                               variable=size_var, value=size).pack(side=tk.LEFT, padx=5)

            # Add "None" option
            ttk.Radiobutton(size_frame, text="None", variable=size_var,
                           value="").pack(side=tk.LEFT, padx=5)

            placement_grid_row += 1

        row += 1

        # PDF Metadata section
        metadata_frame = ttk.LabelFrame(main_frame, text="PDF Metadata (optional)",
                                        padding="10")
        metadata_frame.grid(row=row, column=0, columnspan=3, sticky=(tk.W, tk.E),
                           pady=(10, 10))
        metadata_frame.columnconfigure(1, weight=1)

        ttk.Label(metadata_frame, text="Author:").grid(row=0, column=0, sticky=tk.W,
                                                        padx=(0, 10), pady=5)
        ttk.Entry(metadata_frame, textvariable=self.author).grid(row=0, column=1,
                                                                 sticky=(tk.W, tk.E), pady=5)

        ttk.Label(metadata_frame, text="Subject:").grid(row=1, column=0, sticky=tk.W,
                                                         padx=(0, 10), pady=5)
        ttk.Entry(metadata_frame, textvariable=self.subject).grid(row=1, column=1,
                                                                   sticky=(tk.W, tk.E), pady=5)

        ttk.Label(metadata_frame, text="Keywords:").grid(row=2, column=0, sticky=tk.W,
                                                          padx=(0, 10), pady=5)
        ttk.Entry(metadata_frame, textvariable=self.keywords).grid(row=2, column=1,
                                                                    sticky=(tk.W, tk.E), pady=5)

        row += 1

        # Convert button
        self.convert_btn = ttk.Button(main_frame, text="Convert to PDF",
                                      command=self.convert, style='Accent.TButton')
        self.convert_btn.grid(row=row, column=0, columnspan=3, pady=(20, 10),
                             sticky=(tk.W, tk.E))
        row += 1

        # Progress/Output section
        ttk.Label(main_frame, text="Output:", font=('Helvetica', 10, 'bold')).grid(
            row=row, column=0, sticky=tk.W, pady=(10, 5))
        row += 1

        self.output_text = scrolledtext.ScrolledText(main_frame, height=10,
                                                      state='disabled', wrap=tk.WORD)
        self.output_text.grid(row=row, column=0, columnspan=3, sticky=(tk.W, tk.E, tk.N, tk.S),
                             pady=(0, 10))
        main_frame.rowconfigure(row, weight=1)
        row += 1

        # Status bar
        self.status_var = tk.StringVar(value="Ready")
        status_bar = ttk.Label(main_frame, textvariable=self.status_var,
                              relief=tk.SUNKEN, anchor=tk.W)
        status_bar.grid(row=row, column=0, columnspan=3, sticky=(tk.W, tk.E))

    def browse_input(self):
        """Browse for input Markdown file"""
        filename = filedialog.askopenfilename(
            title="Select Markdown File",
            filetypes=[("Markdown files", "*.md *.markdown"), ("All files", "*.*")]
        )
        if filename:
            self.input_file.set(filename)
            # Auto-suggest output filename
            if not self.output_file.get():
                output = Path(filename).with_suffix('.pdf')
                self.output_file.set(str(output))

    def browse_output(self):
        """Browse for output PDF file"""
        filename = filedialog.asksaveasfilename(
            title="Save PDF As",
            defaultextension=".pdf",
            filetypes=[("PDF files", "*.pdf"), ("All files", "*.*")]
        )
        if filename:
            self.output_file.set(filename)

    def browse_logo(self):
        """Browse for logo file"""
        filename = filedialog.askopenfilename(
            title="Select Logo File",
            filetypes=[
                ("Image files", "*.png *.jpg *.jpeg *.svg"),
                ("PNG files", "*.png"),
                ("JPEG files", "*.jpg *.jpeg"),
                ("SVG files", "*.svg"),
                ("All files", "*.*")
            ]
        )
        if filename:
            self.logo_file.set(filename)

    def log_output(self, message):
        """Add message to output text area"""
        self.output_text.configure(state='normal')
        self.output_text.insert(tk.END, message + '\n')
        self.output_text.see(tk.END)
        self.output_text.configure(state='disabled')

    def clear_output(self):
        """Clear output text area"""
        self.output_text.configure(state='normal')
        self.output_text.delete('1.0', tk.END)
        self.output_text.configure(state='disabled')

    def build_command(self):
        """Build the klasiko command line"""
        # Validate input file
        if not self.input_file.get():
            raise ValueError("Please select an input Markdown file")

        if not os.path.exists(self.input_file.get()):
            raise ValueError(f"Input file not found: {self.input_file.get()}")

        # Find klasiko executable
        klasiko_cmd = self.find_klasiko()

        # Build command
        cmd = [klasiko_cmd, self.input_file.get()]

        # Output file
        if self.output_file.get():
            cmd.extend(['-o', self.output_file.get()])

        # Theme
        if self.theme.get():
            cmd.extend(['--theme', self.theme.get()])

        # Table of contents
        if self.toc_enabled.get():
            cmd.append('--toc')

        # Logo
        if self.logo_file.get() and os.path.exists(self.logo_file.get()):
            cmd.extend(['--logo', self.logo_file.get()])

            # Logo placements
            for position, size_var in self.placement_vars.items():
                size = size_var.get()
                if size:  # Only add if a size is selected
                    cmd.extend(['--logo-placement', f'{position}:{size}'])

        # Metadata
        if self.author.get():
            cmd.extend(['--author', self.author.get()])
        if self.subject.get():
            cmd.extend(['--subject', self.subject.get()])
        if self.keywords.get():
            cmd.extend(['--keywords', self.keywords.get()])

        return cmd

    def find_klasiko(self):
        """Find klasiko executable"""
        # Check if running from bundled executable
        if getattr(sys, 'frozen', False):
            # Running in PyInstaller bundle
            bundle_dir = Path(sys._MEIPASS)
            klasiko_exe = bundle_dir / 'klasiko'
            if sys.platform == 'win32':
                klasiko_exe = bundle_dir / 'klasiko.exe'
            if klasiko_exe.exists():
                return str(klasiko_exe)

        # Check for klasiko in current directory
        if sys.platform == 'win32':
            local_exe = Path('klasiko.exe')
            if local_exe.exists():
                return str(local_exe)

        # Check for klasiko.py in current directory
        local_py = Path('klasiko.py')
        if local_py.exists():
            return sys.executable + ' ' + str(local_py)

        # Try system PATH
        if sys.platform == 'win32':
            return 'klasiko.exe'
        else:
            return 'klasiko'

    def convert(self):
        """Run the conversion in a background thread"""
        try:
            cmd = self.build_command()
        except ValueError as e:
            messagebox.showerror("Validation Error", str(e))
            return

        # Disable button during conversion
        self.convert_btn.configure(state='disabled')
        self.status_var.set("Converting...")
        self.clear_output()

        # Run in thread to avoid freezing GUI
        thread = threading.Thread(target=self.run_conversion, args=(cmd,))
        thread.daemon = True
        thread.start()

    def run_conversion(self, cmd):
        """Run the actual conversion command"""
        try:
            self.log_output(f"Running: {' '.join(cmd)}\n")

            # Run the command
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1
            )

            # Stream output
            for line in process.stdout:
                self.log_output(line.rstrip())

            process.wait()

            # Check result
            if process.returncode == 0:
                self.root.after(0, lambda: self.status_var.set("Conversion completed successfully!"))
                self.log_output("\n✓ Conversion completed successfully!")

                # Ask if user wants to open the PDF
                output = self.output_file.get() or Path(self.input_file.get()).with_suffix('.pdf')
                if os.path.exists(output):
                    self.root.after(0, lambda: self.ask_open_pdf(output))
            else:
                self.root.after(0, lambda: self.status_var.set("Conversion failed"))
                self.log_output(f"\n✗ Conversion failed with exit code {process.returncode}")

        except Exception as e:
            self.log_output(f"\n✗ Error: {str(e)}")
            self.root.after(0, lambda: self.status_var.set("Error occurred"))
        finally:
            self.root.after(0, lambda: self.convert_btn.configure(state='normal'))

    def ask_open_pdf(self, pdf_path):
        """Ask user if they want to open the PDF"""
        result = messagebox.askyesno(
            "Success",
            f"PDF created successfully!\n\n{pdf_path}\n\nWould you like to open it now?"
        )
        if result:
            self.open_file(pdf_path)

    def open_file(self, filepath):
        """Open file with default application"""
        try:
            if sys.platform == 'win32':
                os.startfile(filepath)
            elif sys.platform == 'darwin':
                subprocess.run(['open', filepath])
            else:
                subprocess.run(['xdg-open', filepath])
        except Exception as e:
            messagebox.showerror("Error", f"Could not open file: {str(e)}")


def main():
    """Main entry point"""
    root = tk.Tk()
    app = KlasikoGUI(root)
    root.mainloop()


if __name__ == '__main__':
    main()
