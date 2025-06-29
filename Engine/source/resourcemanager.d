module resourcemanager;

// module Engine.src.resourcemanager;

// Adapted from singleton.d in class public Github Repo

import bindbc.sdl;
import std.stdio;
import std.string;

/// Singleton resource manager for loading and caching images and music.
struct ResourceManager{
    static SetRenderer(SDL_Renderer* renderer){
        mRenderer = renderer;
    }

    /// Returns the singleton instance of the resource manager.
    static ResourceManager* GetInstance(){
        if(mInstance is null){
            mInstance = new ResourceManager();
        }
        return mInstance;
    }

    /// Loads a BMP image file and returns a texture.
    /// Returns a cached version if already loaded.
    static SDL_Texture* LoadBMPResource(string filename){
        if(mRenderer is null){
            writeln("Need to use SetRenderer before loading image resources");
            return null;
        }
        if(filename in mImageResourceMap){
            return mImageResourceMap[filename];
        }
        // Load and store image
        SDL_Surface* surface = SDL_LoadBMP(filename.toStringz);
        if (surface == null) {
            writeln("Failed to load BMP image: ", SDL_GetError().fromStringz);
            return null;
        }

        SDL_Texture* texture = SDL_CreateTextureFromSurface(mRenderer, surface);
        if (texture == null) {
            writeln("Failed to create texture from surface: ", SDL_GetError().fromStringz);
            return null;
        }

        mImageResourceMap[filename] = texture;
        SDL_FreeSurface(surface);
        return mImageResourceMap[filename];
    }

    /// Loads an image using SDL_Image and returns a texture.
    /// Returns a cached version if already loaded.
    static SDL_Texture* LoadImageResource(string filename){
        if(mRenderer is null){
            writeln("Need to use SetRenderer before loading image resources");
            return null;
        }
        if(filename in mImageResourceMap){
            return mImageResourceMap[filename];
        }
        // Load texture
        SDL_Texture* texture = IMG_LoadTexture(mRenderer, filename.toStringz);
        if(texture is null){
            writeln("There was an error loading the image: ", SDL_GetError().fromStringz);
            return null;
        }
        mImageResourceMap[filename] = texture;
        return texture;
    }

    /// Loads a music file and returns a Mix_Music pointer.
    /// Returns a cached version if already loaded.
    static Mix_Music* LoadMusicResource(string filename){
        if(filename in mMusicResourceMap){
            return mMusicResourceMap[filename];
        }
        // Load and store music file
        Mix_Music* m = Mix_LoadMUS(filename.toStringz);
        if (m == null) {
            writeln("Failed to load music file: ");
            writeln(Mix_GetError().fromStringz);
            return null;
        }
        mMusicResourceMap[filename] = m;
        return m;
    }

    /// Frees all cached textures and music on destruction.
    ~this(){
        foreach(SDL_Texture* texture ; mImageResourceMap){
            SDL_DestroyTexture(texture);
        }
        foreach(Mix_Music* music ; mMusicResourceMap){
            Mix_FreeMusic(music);
        }
    }

    private:
        static ResourceManager* mInstance;
        static SDL_Texture*[string] mImageResourceMap;
        static Mix_Music*[string] mMusicResourceMap;
        static SDL_Renderer* mRenderer;
}