#pragma once

namespace dp
{

class OGLContext
{
public:
  virtual ~OGLContext() {}
  virtual void present() = 0;
  virtual void makeCurrent() = 0;
  virtual void setDefaultFramebuffer() = 0;
};

} // namespace dp