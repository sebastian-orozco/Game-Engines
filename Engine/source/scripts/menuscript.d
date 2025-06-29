module menuscript;

import std.stdio, std.string;
import std.process;

import linear;
import gameobject;
import component;
import scripts;
import std.math;

import bindbc.sdl;
import gameapplication;
import resourcemanager;

class MenuScript : IScript{
        Scene *mScene;
        uint mStartTime;
        bool isSceneComplete = false;
        bool startMusic = false;
        bool stopMusic;
        string nextScene = "game";
        

		this(Scene* scene) {
			mScene = scene;
            startMusic = true;
            mStartTime = SDL_GetTicks();
        }

		override void Update(){
            if (startMusic) {
                // writeln("starting music...");
                if (Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024)==-1){
                    writeln("Audio library not working: "~Mix_GetError().fromStringz);
                }

                // Start background music
                Mix_Music* bgMusic = ResourceManager.GetInstance().LoadMusicResource("assets/music/sound_menu.wav");
                if(Mix_PlayMusic(bgMusic, -1) == -1) {
                    writeln("There was an error playing the music: ");
                    writeln(Mix_GetError().fromStringz());
                }

                startMusic = false;
            }

            // Get Keyboard input
            const ubyte* keyboard = SDL_GetKeyboardState(null);
            if(keyboard[SDL_SCANCODE_SPACE] && SDL_GetTicks() - mStartTime > 150){
                isSceneComplete = true;
                if (Mix_PlayingMusic() == 1) {
                    Mix_HaltMusic();
                }
                mScene.mGameState.mStringMap["nextScene"] = "MainLevel";
            }
            if(keyboard[SDL_SCANCODE_E]){
                auto result = execute(["python3", "tilemap-v2.py"]);
                // writeln("Output: ", result.output);
                if (result.status != 0) {
                    writeln("Error running script!");
                }
            }
            if(keyboard[SDL_SCANCODE_Q]){
                if (Mix_PlayingMusic() == 1) {
                    Mix_HaltMusic();
                }
                mScene.mGameState.mIntMap["gameOver"] = 1;
            }
		}

		override string GetName() {
			return "MenuScript";
		}

		private:
		size_t mOwner;
}