module winscript;
import std.stdio, std.string;

import linear;
import gameobject;
import component;
import scripts;
import std.math;

import bindbc.sdl;
import gameapplication;
import resourcemanager;

class WinScreenScript : IScript{
        Scene *mScene;
        uint mStartTime;
        bool isSceneComplete = false;
        bool startMusic = false;
        bool stopMusic;
        string nextScene = "game";
        

        this(Scene* scene) {
            mScene = scene;
            mStartTime = SDL_GetTicks();
            startMusic = true;
        }

        override void Update(){
            if (startMusic) {
                // writeln("starting music...");
                if (Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024)==-1){
                    writeln("Audio library not working: "~Mix_GetError().fromStringz);
                }

                // Start background music
                Mix_Music* bgMusic = ResourceManager.GetInstance().LoadMusicResource("assets/music/sound_game_win.wav");
                if(Mix_PlayMusic(bgMusic, -1) == -1) {
                    writeln("There was an error playing the music: ");
                    writeln(Mix_GetError().fromStringz());
                }

                startMusic = false;
            }

            // Get Keyboard input
            const ubyte* keyboard = SDL_GetKeyboardState(null);
            if(keyboard[SDL_SCANCODE_Q]){
                if (Mix_PlayingMusic() == 1) {
                    Mix_HaltMusic();
                }
                mScene.mGameState.mIntMap["gameOver"] = 1;
            }
            if(keyboard[SDL_SCANCODE_SPACE]){
                if (Mix_PlayingMusic() == 1) {
                    Mix_HaltMusic();
                }
                mScene.mGameState.mStringMap["nextScene"] = "Menu";
            }
        }

        override string GetName() {
            return "WinScreenScript";
        }

        private:
        size_t mOwner;
}
