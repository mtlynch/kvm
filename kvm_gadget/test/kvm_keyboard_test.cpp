// Copyright 2020 Christopher A. Taylor

#include "kvm_transport.hpp"
#include "kvm_logger.hpp"
using namespace kvm;

static logger::Channel Logger("KeyboardTest");

int main(int argc, char* argv[])
{
    SetCurrentThreadName("Main");

    CORE_UNUSED(argc);
    CORE_UNUSED(argv);

    Logger.Info("kvm_keyboard_test");

    KeyboardEmulator keyboard;

    if (!keyboard.Initialize()) {
        Logger.Error("Keyboard initialization failed");
        return kAppFail;
    }

    InputTransport transport;
    transport.Keyboard = &keyboard;

    // Press "A" key and release
    uint8_t reports[7] = {
        0x01, 0x02, 0x00, 0x04,
        0x02, 0x01, 0x00,
    };

    if (!transport.ParseReports(reports, 7)) {
        Logger.Error("ParseReports failed");
        return kAppFail;
    }

    return kAppSuccess;
}
