# author: sebastian orozco
# file: tilemap.py
# citation: As we have largely not discussed Python and the tkinter package in this course, 
# I used generative AI (ChatGPT) for assistance in completing this assignment

import tkinter as tk
from tkinter import filedialog, simpledialog
from PIL import Image, ImageTk
import json

class TileMapEditor:
    def __init__(self, root):
        self.root = root
        self.root.title("Tile Map Editor")
        self.GRID_SIZE =40  # tile size (32x32 pixels)

        # === main container ===
        self.main_frame = tk.Frame(root)
        self.main_frame.pack(fill=tk.BOTH, expand=True)

        # === left tileset viewer panel === 
        self.left_panel = tk.Frame(self.main_frame, width=300)
        self.left_panel.pack(side=tk.LEFT, fill=tk.Y)

        # --- toolbar ---
        self.toolbar = tk.Frame(self.left_panel)
        self.toolbar.pack(side=tk.TOP)

        self.grid_offset_x = 90
        self.grid_offset_y = 230

        # tileset upload button
        # self.upload_button = tk.Button(self.toolbar, text="Upload PNG", command=self.upload_png)
        # self.upload_button.pack(side=tk.LEFT, padx=5, pady=5)

        # resize map button
        # self.grid_size_button = tk.Button(self.toolbar, text="Resize Map", command=self.open_grid_size_dialog)
        # self.grid_size_button.pack(side=tk.LEFT, padx=5, pady=5)

        # save button
        # self.save_button = tk.Button(self.toolbar, text="Save PNG", command=self.save_map_as_png)
        # self.save_button.pack(side=tk.LEFT, padx=5, pady=5)

        self.export_button = tk.Button(self.toolbar, text="Save", command=self.export_map)
        self.export_button.pack(side=tk.LEFT, padx=5, pady=5)

        # --- scrollable canvas to view tileset ---
        self.image_frame = tk.Frame(self.left_panel)
        self.image_frame.pack(fill=tk.BOTH, expand=True)

        self.image_canvas = tk.Canvas(self.image_frame, bg='white')
        self.v_scroll = tk.Scrollbar(self.image_frame, orient=tk.VERTICAL, command=self.image_canvas.yview)
        self.h_scroll = tk.Scrollbar(self.image_frame, orient=tk.HORIZONTAL, command=self.image_canvas.xview)

        self.image_canvas.configure(yscrollcommand=self.v_scroll.set, xscrollcommand=self.h_scroll.set)

        # grid layout for scrollbars (necessary to force horizontal scrollbar on the bottom)
        self.image_canvas.grid(row=0, column=0, sticky="nsew")
        self.v_scroll.grid(row=0, column=1, sticky="ns")
        self.h_scroll.grid(row=1, column=0, sticky="ew")

        self.image_frame.rowconfigure(0, weight=1)
        self.image_frame.columnconfigure(0, weight=1)

        # === right editor panel ===
        self.right_panel = tk.Frame(self.main_frame, bg="#f0f0f0")
        self.right_panel.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True)

        # --- scrollable canvas for placing tiles ---
        self.map_frame = tk.Frame(self.right_panel)
        self.map_frame.pack(fill=tk.BOTH, expand=True)

        self.editor_canvas = tk.Canvas(self.map_frame, bg='lightgray')
        self.v_map_scroll = tk.Scrollbar(self.map_frame, orient=tk.VERTICAL, command=self.editor_canvas.yview)
        self.h_map_scroll = tk.Scrollbar(self.map_frame, orient=tk.HORIZONTAL, command=self.editor_canvas.xview)

        self.editor_canvas.configure(yscrollcommand=self.v_map_scroll.set, xscrollcommand=self.h_map_scroll.set)

        # again, grid layout for correct scrollbar placement
        self.editor_canvas.grid(row=0, column=0, sticky="nsew")
        self.v_map_scroll.grid(row=0, column=1, sticky="ns")
        self.h_map_scroll.grid(row=1, column=0, sticky="ew")

        self.map_frame.rowconfigure(0, weight=1)
        self.map_frame.columnconfigure(0, weight=1)

        self.status_label = tk.Label(self.root, text="", anchor="w", fg="red")
        self.status_label.pack(side=tk.BOTTOM, fill=tk.X)

        # === tileset and map state tracking ===
        self.tk_image = None              # tk image reference to entire tileset
        self.tileset_image = None         # original pil image
        self.selected_tile_coords = None  # (row, col)
        self.selected_tile_image = None   # cropped tile 
        self.tile_highlight = None        # red rectangle to highlight tile
        self.tile_data = []
        self.map_rows = 3
        self.map_cols = 15

        # === init default state ===
        self.update_tileset("assets/images/enemy_sprite.png")  
        self.draw_map_grid() 

        self.set_editor_background("assets/images/map.png")

        self.draw_clickable_boundary()

    def set_editor_background(self, texture_path):
        texture_image = Image.open(texture_path)

        self.texture_tk_image = ImageTk.PhotoImage(texture_image)

        self.editor_canvas.create_image(0, 0, anchor=tk.NW, image=self.texture_tk_image)

        self.editor_canvas.image = self.texture_tk_image



    def open_grid_size_dialog(self):
        rows = simpledialog.askinteger("Grid Rows", "Please enter number of rows:", minvalue=1, initialvalue=20)
        cols = simpledialog.askinteger("Grid Columns", "Please enter number of columns:", minvalue=1, initialvalue=40)
        self.draw_map_grid(rows, cols)

    # def upload_png(self):
    #     file_path = filedialog.askopenfilename(
    #         filetypes=[("PNG Files", "*.png")],
    #         title="Please select a PNG file"
    #     )
    #     if file_path:
    #         self.update_tileset(file_path)


    def update_tileset(self, file_path):
        # load img
        image = Image.open(file_path)

        # store img
        self.tileset_image = image

        # get tinker compatible img
        self.tk_image = ImageTk.PhotoImage(image)

        # clear + draw img
        self.image_canvas.delete("all")
        self.image_canvas.create_image(0, 0, anchor=tk.NW, image=self.tk_image)
        self.image_canvas.config(scrollregion=(0, 0, image.width, image.height)) # update scrolling to fit size of new img  
        self.draw_grid(image.width, image.height)

        self.image_canvas.bind("<Button-1>", self.on_tileset_click)

    def draw_grid(self, width, height):
        grid_color = "#cccccc"
        for x in range(0, width, self.GRID_SIZE):
            self.image_canvas.create_line(x, 0, x, height, fill=grid_color)
        for y in range(0, height, self.GRID_SIZE):
            self.image_canvas.create_line(0, y, width, y, fill=grid_color)


    def draw_map_grid(self):
        self.editor_canvas.delete("all")

        # Define desired size
        target_width = 2800
        target_height = 120

        # Calculate number of columns and rows based on tile size
        cols = (target_width-300) // self.GRID_SIZE
        rows = target_height // self.GRID_SIZE

        # Store rows and cols
        self.map_rows = rows
        self.map_cols = cols
        self.tile_data = [[None for _ in range(cols)] for _ in range(rows)]

        # Draw the grid rectangles
        for row in range(rows):
            for col in range(cols):
                x1 = col * self.GRID_SIZE + self.grid_offset_x
                y1 = row * self.GRID_SIZE + self.grid_offset_y
                x2 = x1 + self.GRID_SIZE
                y2 = y1 + self.GRID_SIZE
                self.editor_canvas.create_rectangle(x1, y1, x2, y2, outline="#999")

        self.editor_canvas.config(scrollregion=(0, 0, target_width, target_height))
        self.editor_canvas.bind("<Button-1>", self.on_map_click)


    def on_tileset_click(self, event):
        x, y = self.image_canvas.canvasx(event.x), self.image_canvas.canvasy(event.y)
        col = x // self.GRID_SIZE
        row = y // self.GRID_SIZE
        # print(f"clicked ({x}, {y}) aka tile ({row}, {col})")
        self.selected_tile_coords = (row, col)

        # crop tile from tileset
        left = col * self.GRID_SIZE
        upper = row * self.GRID_SIZE
        right = left + self.GRID_SIZE
        lower = upper + self.GRID_SIZE
        rect = (left, upper, right, lower)

        tile = self.tileset_image.crop(rect)
        self.selected_tile_image = ImageTk.PhotoImage(tile)

        # remove prev highlight
        if self.tile_highlight:
            self.image_canvas.delete(self.tile_highlight)

        # draw new highlight (aka red rectangle around tile)
        self.tile_highlight = self.image_canvas.create_rectangle(
            left, upper, right-8, lower-8, outline='red', width=2
        )



    def on_map_click(self, event):
        if not self.selected_tile_image:
            return  

        x, y = self.editor_canvas.canvasx(event.x), self.editor_canvas.canvasy(event.y)
        col = (x - self.grid_offset_x) // self.GRID_SIZE
        row = (y - self.grid_offset_y) // self.GRID_SIZE
        draw_x = col * self.GRID_SIZE + self.grid_offset_x
        draw_y = row * self.GRID_SIZE + self.grid_offset_y

        if not (0 <= row < self.map_rows and 0 <= col < self.map_cols):
            self.status_label.config(text="Click was outside the grid.")
            return
        else:
            self.status_label.config(text="")

        # draw selected tile onto map
        self.editor_canvas.create_image(draw_x, draw_y, anchor=tk.NW, image=self.selected_tile_image)

        # track placement aka (ImageTk.PhotoImage, x, y)
        if not hasattr(self, 'placed_tiles'):
            self.placed_tiles = []
        self.placed_tiles.append((self.selected_tile_image, draw_x, draw_y))
        self.tile_data[int(row)][int(col)] = 1


    def draw_clickable_boundary(self):
        width = self.map_cols * self.GRID_SIZE
        height = self.map_rows * self.GRID_SIZE
        self.editor_canvas.create_rectangle(self.grid_offset_x, self.grid_offset_y, self.grid_offset_x+width, self.grid_offset_y+height, outline="red", width=2)

    def save_map_as_png(self):
        if not hasattr(self, 'placed_tiles') or not self.placed_tiles:
            print("error: nothing to save")
            return

        # get map size from scrollregion
        bbox = self.editor_canvas.bbox("all")
        if not bbox:
            print("could not determine canvas bounds")
            return
        x1, y1, x2, y2 = bbox
        map_width = int(x2)
        map_height = int(y2)

        # create blank transparent image
        output_image = Image.new("RGBA", (map_width, map_height), (255, 255, 255, 0))

        # paste tiles one by one onto output img
        for tile_imgtk, x, y in self.placed_tiles:
            tile_pil = ImageTk.getimage(tile_imgtk)
            output_image.paste(tile_pil, (int(x), int(y)), tile_pil)  


        # save
        save_path = filedialog.asksaveasfilename(defaultextension=".png", filetypes=[("PNG Files", "*.png")])
        if save_path:
            output_image.save(save_path)
            print(f"Map saved to: {save_path}")

    def export_map(self):
        if not self.tile_data or not hasattr(self, 'placed_tiles'):
            print("No map to export.")
            return

        file_path = "testTile.json"
        if not file_path:
            return

        with open(file_path, "r") as f:
            scene_data = json.load(f)

        objects = scene_data.get("sceneTree", {}).get("objects", [])
        tree_nodes = scene_data.get("sceneTree", {}).get("treeNodes", [])

        objects_to_remove = []
        tree_nodes_to_remove = []

        for obj in objects:
            if "name" in obj and obj["name"].startswith("Enemy"):
                objects_to_remove.append(obj)

        for node in tree_nodes:
            if "objName" in node and node["objName"].startswith("Enemy"):
                tree_nodes_to_remove.append(node)

        # Remove the enemies from the lists
        for obj in objects_to_remove:
            objects.remove(obj)
        
        for node in tree_nodes_to_remove:
            tree_nodes.remove(node)

        enemy_count = 0

        for tile_imgtk, x, y in self.placed_tiles:
            enemy_name = f"Enemy{enemy_count}"

            enemy_object = {
                "components": {
                    "ANIMATEDTEXTURE": {
                        "currAnimation": "run",
                        "currFrame": 0,
                        "filename": "assets/images/enemy.json",
                        "lastFrame": 5
                    },
                    "COLLISION": {
                        "rect": [int(x), int(y)+10, 30, 30],
                        "xOffset": 0,
                        "yOffset": 10
                    },
                    "TEXTURE": {
                        "angle": 0.0,
                        "destScale": [0.0, 0.0],
                        "filename": "assets/images/enemy_spritesheet.png",
                        "rect": [0, 0, 30, 40],
                        "srcRect": [0, 0, 0, 0]
                    },
                    "TRANSFORM": {
                        "local": [
                            [1.0, 0.0, float(x)],
                            [0.0, 1.0, float(y)],
                            [0.0, 0.0, 1.0]
                        ],
                        "world": [
                            [1.0, 0.0, 0.0],
                            [0.0, 1.0, 0.0],
                            [0.0, 0.0, 1.0]
                        ]
                    }
                },
                "name": enemy_name,
                "scripts": ["EnemyScript"]
            }

            
            tree_node = {
                "name": enemy_name.lower(),
                "objName": enemy_name,
                "parent": 0
            }

            objects.append(enemy_object)
            tree_nodes.append(tree_node)

            enemy_count += 1

        
        save_path = "testTile.json"
        if save_path:
            with open(save_path, "w") as f:
                json.dump(scene_data, f, indent=2)
            print(f"Modified scene exported to {save_path}")
        self.root.destroy()



if __name__ == "__main__":
    root = tk.Tk()
    root.geometry("1000x500")
    app = TileMapEditor(root)
    root.mainloop()
