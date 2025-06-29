import tkinter as tk

import sys
from PIL import Image, ImageTk

TILE_SIZE = 32
MAP_WIDTH, MAP_HEIGHT = 10, 10
TILESET_COLUMNS = 8  # adjust based on your tileset image

class TileMapEditor:
    def __init__(self, root, tileset_image):
        self.root = root
        self.tileset_image = Image.open(tileset_image)
        self.tiles = []
        self.divide_tile_image()
        self.selected_tile_index = 0
        self.tile_map = [[-1 for _ in range(MAP_HEIGHT)] for _ in range(MAP_WIDTH)]

        self.top_frame = tk.Frame(root)
        self.top_frame.pack(side="top", fill="x")

        self.map_label = tk.Label(self.top_frame, text="Tile Map", font=("Calibri", 20, "bold"))
        self.map_label.pack(side="left", padx=(130, 0), pady=20)

        self.picker_label = tk.Label(self.top_frame, text="Tile Picker", font=("Calibri", 20, "bold"))
        self.picker_label.pack(side="right", padx=(0, 30), pady=20)

        self.main_frame = tk.Frame(root)
        self.main_frame.pack(side="top")

        self.map_canvas = tk.Canvas(self.main_frame,
                            width=MAP_WIDTH * TILE_SIZE,
                            height=MAP_HEIGHT * TILE_SIZE,
                            bg="white")
        self.map_canvas.pack(side="left", padx=20, pady=10)

        self.picker_frame = tk.Frame(self.main_frame)
        self.picker_frame.pack(side="right", fill="y", padx=20, pady=10)

        self.scrollbar = tk.Scrollbar(self.picker_frame, orient="vertical")
        self.scrollbar.pack(side="right", fill="y")

        self.menu_canvas = tk.Canvas(self.picker_frame,
                             width=4 * 32,
                             height=MAP_HEIGHT * TILE_SIZE,
                             bg="lightgray",
                             yscrollcommand=self.scrollbar.set)
        self.menu_canvas.pack(side="left", fill="both", expand=True)

        self.scrollbar.config(command=self.menu_canvas.yview)
        self.menu_canvas.bind_all("<MouseWheel>", self.on_mousewheel)

        self.map_canvas.bind("<Button-1>", self.on_click)

        self.highlight_tile = None

        self.draw_tile_menu()
        self.draw_map()

    def divide_tile_image(self):
        width, height = self.tileset_image.size
        step = 17
        i = 0
        for y in range(0, height - 16 + 1, step):
            for x in range(0, width - 16 + 1, step):
                tile = self.tileset_image.crop((x, y, x + 16, y + 16))
                tile = tile.resize((32, 32), Image.NEAREST)
                self.tiles.append(ImageTk.PhotoImage(tile))
                i += 1

    def draw_tile_menu(self):
        self.menu_canvas.delete("all")

        for i, tile in enumerate(self.tiles):
            x = (i % 4) * 32
            y = (i // 4) * 32
            self.menu_canvas.create_image(x, y, image=tile, anchor="nw", tags=f"tile_{i}")
            self.menu_canvas.tag_bind(f"tile_{i}", "<Button-1>", lambda e, idx=i: self.select_tile(idx))

        total_rows = (len(self.tiles) + 3) // 4
        content_height = total_rows * 32
        self.menu_canvas.config(scrollregion=(0, 0, 4 * 32, content_height))

    def draw_map(self):
        self.draw_grid()
        self.map_canvas.delete("tilemap")
        for x in range(MAP_WIDTH):
            for y in range(MAP_HEIGHT):
                idx = self.tile_map[x][y]
                if idx != -1:
                    self.map_canvas.create_image(x * TILE_SIZE, y * TILE_SIZE,
                                             image=self.tiles[idx], anchor="nw", tags="tilemap")
                    
    def draw_grid(self):
        for x in range(0, MAP_WIDTH * TILE_SIZE, TILE_SIZE):
            self.map_canvas.create_line(
                x, 0, x, MAP_HEIGHT * TILE_SIZE,
                fill="gray", dash=(2, 4)
            )
        for y in range(0, MAP_HEIGHT * TILE_SIZE, TILE_SIZE):
            self.map_canvas.create_line(
                0, y, MAP_WIDTH * TILE_SIZE, y,
                fill="gray", dash=(2, 4)
            )

    def select_tile(self, idx):
        self.selected_tile_index = idx
        x = (idx % 4) * 32 
        y = (idx // 4) * 32
        # Remove old highlight if it exists
        if self.highlight_tile is not None:
            self.menu_canvas.delete(self.highlight_tile)

        # Draw a new rectangle around the selected tile
        self.highlight_tile = self.menu_canvas.create_rectangle(
            x, y, x + 32, y + 32,
            outline="red", width=3
    )

    def on_click(self, event):
        grid_x = event.x // TILE_SIZE
        grid_y = event.y // TILE_SIZE
        if grid_x < MAP_WIDTH and grid_y < MAP_HEIGHT:
            self.tile_map[grid_x][grid_y] = self.selected_tile_index
            self.draw_map()

    def on_mousewheel(self, event):
        self.menu_canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")



if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python editor.py <tileset.png>")
        sys.exit(1)

    tileset_image = sys.argv[1]
    root = tk.Tk()
    editor = TileMapEditor(root, tileset_image)
    root.mainloop()