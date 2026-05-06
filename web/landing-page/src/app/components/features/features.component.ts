import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RevealDirective } from '../../directives/reveal.directive';

interface Feature {
  icon: string;
  title: string;
  desc: string;
}

@Component({
  selector: 'app-features',
  standalone: true,
  imports: [CommonModule, RevealDirective],
  templateUrl: './features.component.html',
  styleUrl: './features.component.scss'
})
export class FeaturesComponent {
  features: Feature[] = [
    {
      icon: '🗺️',
      title: 'Mapa interactivo',
      desc: 'Localiza eventos cercanos en tiempo real con geolocalización integrada.'
    },
    /*{
      icon: '🔔',
      title: 'Notificaciones',
      desc: 'Recibe alertas personalizadas cuando se publiquen eventos de tu interés.'
    }*/
    {
      icon: '📅',
      title: 'Agenda completa',
      desc: 'Vista de calendario con todos los eventos filtrados por días.'
    },
    {
      icon: '🌍',
      title: 'Para residentes y turistas',
      desc: 'Diseñado para que tanto emeritenses como visitantes disfruten de la ciudad.'
    },
    {
      icon: '🎫',
      title: 'Información detallada',
      desc: 'Horarios, ubicación, imagen y descripción completa de cada evento.'
    },
    {
      icon: '🔍',
      title: 'Búsqueda y filtros',
      desc: 'Encuentra exactamente lo que buscas por categoría, título o ubicación.'
    }
  ];
}
