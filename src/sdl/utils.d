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
R enforceSDL(R)(R result) {
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
    return result;
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

/**
 *  FPS計測・待機用構造体
 */
struct FpsWatch {

    /**
     *  Params:
     *      fps = 秒間フレーム数。0より大きい値を指定
     */
    this(Uint32 fps)
    in {
        assert(fps > 0);
    } body {
        fps_ = fps;

        // 切り上げで計算
        millsPerFrame_ = (MILLS_PER_SEC + fps - 1) / fps;
    }

    /// FPSリセット、フレーム開始
    void reset() {
        lastTicks_ = SDL_GetTicks();
        resetFps();
    }

    /// FPSのみリセット
    void resetFps() {
        totalFrames_ = 0;
        totalElapse_ = 0;
    }

    /// 次フレーム時刻まで待機
    void waitNextFrame() {
        // 開始時刻から現在までの間隔
        immutable elapse = SDL_GetTicks() - lastTicks_;

        // 待機時間も含めたフレーム全体の間隔
        // とりあえずFPS通りの値を設定
        Uint32 frameElapse = millsPerFrame_;

        // 時間切れかどうか
        if(elapse >= millsPerFrame_) {
            // 別スレッド駆動
            SDL_Delay(0);

            // 時間切れだったので、実際の間隔を設定
            frameElapse = elapse;
        } else {
            // 次フレームの時刻まで待つ
            SDL_Delay(millsPerFrame_ - elapse);
        }

        // 次のフレームへ
        totalElapse_ += frameElapse;
        lastTicks_ += frameElapse;
        ++totalFrames_;
    }

    /**
     *  Returns:
     *      計測したFPSを返す。
     */
    @property double actualFps() const pure nothrow @safe {
        if(totalElapse_ == 0) {
            return fps_;
        }

        // フレーム数 / 描画に掛かった秒数
        return (cast(double)totalFrames_) * MILLS_PER_SEC / totalElapse_;
    }

    /// FPS計測開始からの合計フレーム数
    @property size_t totalFrames() const pure nothrow @safe {
        return totalFrames_;
    }

    /// FPS計測開始からの合計ミリ秒数
    @property size_t totalElapse() const pure nothrow @safe {
        return totalElapse_;
    }
private:

    /// 1秒当たりミリ秒数
    enum MILLS_PER_SEC = 1000;

    /// FPS
    immutable Uint32 fps_;

    /// 1フレーム当たりミリ秒数
    immutable Uint32 millsPerFrame_;

    /// 直近のフレーム終了時刻
    Uint32 lastTicks_;

    /// トータルの計測時間
    Uint64 totalElapse_;

    /// トータルの描画フレーム数
    size_t totalFrames_;
}

