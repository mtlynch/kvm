// Copyright 2020 Christopher A. Taylor

/*
    Memory pool allocator for video frame images in various formats
*/

#pragma once

#include "kvm_core.hpp"

#include <memory>
#include <vector>
#include <mutex>

namespace kvm {


//------------------------------------------------------------------------------
// Constants

enum class PixelFormat
{
    YUV420P,
    YUV422P,
    YUYV,
    NV12,
    RGB24,
};


//------------------------------------------------------------------------------
// Frame

struct Frame
{
    Frame();
    ~Frame();

    int Width = 0;
    int Height = 0;
    PixelFormat Format = PixelFormat::YUV422P;
    int AllocatedBytes = 0;

    uint8_t* Planes[3];
};


//------------------------------------------------------------------------------
// FramePool

class FramePool
{
public:
    std::shared_ptr<Frame> Allocate(int w, int h, PixelFormat format);

    void Release(const std::shared_ptr<Frame>& frame);

protected:
    std::mutex Lock;
    std::vector<std::shared_ptr<Frame>> Freed;
};


} // namespace kvm
