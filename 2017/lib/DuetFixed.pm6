use Duet;

# --- Part Two ---
#
# As you congratulate yourself for a job well done, you notice that the
# documentation has been on the back of the tablet this entire time. While you
# actually got most of the instructions correct, there are a few key
# differences. This assembly code isn't about sound at all - it's meant to be
# run twice at the same time.
#
# Each running copy of the program has its own set of registers and follows the
# code independently - in fact, the programs don't even necessarily run at the
# same speed. To coordinate, they use the send (snd) and receive (rcv)
# instructions:
#
#     snd X sends the value of X to the other program. These values wait in a
#     queue until that program is ready to receive them. Each program has its
#     own message queue, so a program can never receive a message it sent.
#
#     rcv X receives the next value and stores it in register X. If no values
#     are in the queue, the program waits for a value to be sent to it.
#     Programs do not continue to the next instruction until they have received
#     a value. Values are received in the order they are sent.
#
# Each program also has its own program ID (one 0 and the other 1); the
# register p should begin with this value.

class DuetFixed is Duet {
    has Int $.id;
    has Int @.queue;

    submethod BUILD(:$!id=0) { self.set( 'p', $!id ) }

    method rcv(Str $r) {
        #($!id, $.i, @!queue).say;
        if not @!queue {
            self.jgz( 1, 0 ); # move back to this instruction to redo
            return Nil;
        }

        self.set( $r, @!queue.shift );
    }

    method add-to-queue(Int $v) { @!queue.append($v) }
}

