package com.mapswithme.maps;

import android.os.Build;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.util.DisplayMetrics;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;

import com.mapswithme.maps.base.BaseMwmFragment;

public abstract class RenderFragment extends BaseMwmFragment
                                     implements View.OnTouchListener,
                                                SurfaceHolder.Callback
{
  // Should be equal to values from Framework.cpp MultiTouchAction enum
  private static final int NATIVE_ACTION_UP = 0x1;
  private static final int NATIVE_ACTION_DOWN = 0x2;
  private static final int NATIVE_ACTION_MOVE = 0x3;
  private static final int NATIVE_ACTION_CANCEL = 0x4;
  private int mLastPointerId = 0;
  private SurfaceHolder mSurfaceHolder = null;
  private int m_displayDensity = 0;

  @Override
  public void surfaceCreated(SurfaceHolder surfaceHolder)
  {
    mSurfaceHolder = surfaceHolder;
    if (isEngineCreated())
      attachSurface(mSurfaceHolder.getSurface());
    else
      InitEngine();
  }

  @Override
  public void surfaceChanged(SurfaceHolder surfaceHolder, int i, int w, int h)
  {
    surfaceResized(w, h);
  }

  @Override
  public void surfaceDestroyed(SurfaceHolder surfaceHolder)
  {
    mSurfaceHolder = null;

    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.HONEYCOMB ||
        getActivity() == null || !getActivity().isChangingConfigurations())
    {
      MWMApplication.get().clearFunctorsOnUiThread();
      destroyEngine();
    }
    else
    {
      detachSurface();
    }
  }

  public boolean isRenderingInitialized()
  {
    return isEngineCreated();
  }

  @Override
  public void onViewCreated(View view, @Nullable Bundle savedInstanceState)
  {
    super.onViewCreated(view, savedInstanceState);
    final SurfaceView surfaceView = (SurfaceView) view.findViewById(R.id.map_surfaceview);
    surfaceView.getHolder().addCallback(this);
  }

  @Override
  public void onCreate(Bundle b)
  {
    super.onCreate(b);
    final DisplayMetrics metrics = new DisplayMetrics();
    getActivity().getWindowManager().getDefaultDisplay().getMetrics(metrics);
    m_displayDensity = metrics.densityDpi;
  }

  @Override
  public boolean onTouch(View view, MotionEvent event)
  {
    final int count = event.getPointerCount();

    if (count == 0)
      return false;

    int action = event.getActionMasked();
    switch (action)
    {
    case MotionEvent.ACTION_POINTER_UP:
    case MotionEvent.ACTION_UP:
      action = NATIVE_ACTION_UP;
      break;
    case MotionEvent.ACTION_POINTER_DOWN:
    case MotionEvent.ACTION_DOWN:
      action = NATIVE_ACTION_DOWN;
      break;
    case MotionEvent.ACTION_MOVE:
      action = NATIVE_ACTION_MOVE;
      break;
    case MotionEvent.ACTION_CANCEL:
      action = NATIVE_ACTION_CANCEL;
      break;
    }

    switch (count)
    {
    case 1:
      {
        mLastPointerId = event.getPointerId(0);

        final float x0 = event.getX();
        final float y0 = event.getY();

        return onTouch(action, true, false, x0, y0, 0, 0);
      }
    default:
      {
        final float x0 = event.getX(0);
        final float y0 = event.getY(0);

        final float x1 = event.getX(1);
        final float y1 = event.getY(1);

        if (event.getPointerId(0) == mLastPointerId)
          return onTouch(action, true, true, x0, y0, x1, y1);
        else
          return onTouch(action, true, true, x1, y1, x0, y0);
      }
    }
  }

  protected abstract void applyWidgetPivots(final int mapHeight, final int mapWidth);

  private void InitEngine()
  {
    if (mSurfaceHolder != null)
    {
      if (createEngine(mSurfaceHolder.getSurface(), m_displayDensity))
        onRenderingInitialized();
      else
        reportUnsupported();
    }
  }

  abstract public void onRenderingInitialized();
  abstract public void reportUnsupported();

  private native boolean createEngine(Surface surface, int density);
  private native boolean isEngineCreated();
  private native void surfaceResized(int w, int h);
  private native void destroyEngine();
  private native void detachSurface();
  private native void attachSurface(Surface surface);
  private native boolean onTouch(int actionType, boolean hasFirst, boolean hasSecond, float x1, float y1, float x2, float y2);
}
