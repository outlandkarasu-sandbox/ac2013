/**
 *  SDL用ユーティリティ
 */
module sdl.utils;

import sdl.bindings;
import std.c.string : strlen;

/**
 *  SDLエラー発生時の例外
 */
class SDLException : Exception {

    /**
     *  Params:
     *      msg = エラーメッセージ
     */
    this(string msg) {
        super(msg);
    }
}

/**
 *  SDL関数の戻り値をチェックする。
 *  エラー発生時はSDLExceptionを投げる。
 *
 *  Params:
 *      result = SDL関数の戻り値
 *  Throws:
 *      SDLException resultが0の場合に投げられる。
 */
void enforceSDL(R)(R result) {
    // 戻り値の型に応じてエラー判定を行う。
    static if(is(R : void*)) {
        if(result is null) {
            throwSdlException();
        }
    } else static if(is(R : int)) {
        if(result != 0) {
            throwSdlException();
        }
    }
}

/**
 *  SDL例外をスローする。
 *
 *  Throws:
 *      SDLException 現在のエラーメッセージを格納したSDL例外。
 */
void throwSdlException() {
    auto msg = SDL_GetError();
    throw new SDLException(msg[0..strlen(msg)].idup);
}

