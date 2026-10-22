// Worker entry point: routes requests to one Room Durable Object per code.
import { handle, type Env } from "./api.ts";

export { Room } from "./room.ts";

export default {
  fetch(request: Request, env: Env): Promise<Response> {
    return handle(request, env);
  },
};
