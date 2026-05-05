import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RevealDirective } from '../../directives/reveal.directive';

interface Member {
  name: string;
  role: string;
  initials: string;
  color: string;
}

@Component({
  selector: 'app-team',
  standalone: true,
  imports: [CommonModule, RevealDirective],
  templateUrl: './team.component.html',
  styleUrl: './team.component.scss'
})
export class TeamComponent {
  members: Member[] = [
    {
      name: 'Adrián Pérez Morales',
      role: 'Desarrollador',
      initials: 'AP',
      color: '#F5A623'
    },
    {
      name: 'David Muñoz Collado',
      role: 'Desarrollador',
      initials: 'DM',
      color: '#4299E1'
    },
    {
      name: 'Eva Retamar Muñoz',
      role: 'Desarrolladora',
      initials: 'ER',
      color: '#68D391'
    }
  ];
}
