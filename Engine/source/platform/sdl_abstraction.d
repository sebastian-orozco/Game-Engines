// Load the SDL2 library
module sdl_abstraction;

import std.stdio;
import std.string;

import bindbc.sdl;
import loader = bindbc.loader.sharedlib;
// global variable for sdl;
const SDLSupport ret;
/// At the module level we perform any initialization before our program
/// executes. Effectively, what I want to do here is make sure that the SDL
/// library successfully initializes.
shared static this(){
		// Load the SDL libraries from bindbc-sdl
		// on the appropriate operating system
    version(Windows){
    		writeln("Searching for SDL on Windows");
				ret = loadSDL("SDL2.dll");
		}
  	version(OSX){
      	writeln("Searching for SDL on Mac");
        ret = loadSDL();
    }
    version(linux){ 
      	writeln("Searching for SDL on Linux");
				ret = loadSDL();
		}

		// Error if SDL cannot be loaded
    if(ret != sdlSupport){
        writeln("error loading SDL library");    
        foreach( info; loader.errors){
            writeln(info.error,':', info.message);
        }
    }
    if(ret == SDLSupport.noLibrary){
        writeln("error no library found");    
    }
    if(ret == SDLSupport.badLibrary){
        writeln("Eror badLibrary, missing symbols, perhaps an older or very new version of SDL is causing the problem?");
    }
    // Initialize SDL
    if(SDL_Init(SDL_INIT_EVERYTHING) !=0){
        writeln("SDL_Init: ", fromStringz(SDL_GetError()));
    }else{
		writeln("SDL initialized");
	}

    if(loadSDLImage() != sdlImageSupport) {
        writeln("Error loading SDL Image");
    }
    if(loadSDLMixer() != sdlMixerSupport) {
        writeln("Error loading SDL Mixer");
    }
    if(loadSDLTTF() != sdlTTFSupport) {
        writeln("Error loading SDL TTF");
    }
    if (TTF_Init() == -1) {
        writeln("Failed to initialize SDL_ttf: ", fromStringz(TTF_GetError()));
    }
}

/// At the module level, when we terminate, we make sure to 
/// terminate SDL, which is initialized at the start of the application.
shared static ~this(){
    // Quit the SDL Application 
    SDL_Quit();
		writeln("Ending application--good bye!");
}